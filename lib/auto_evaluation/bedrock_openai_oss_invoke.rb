module AutoEvaluation
  class BedrockOpenAIOssInvoke
    class InvalidToolCallError < StandardError; end
    class MissingToolCallArgumentsError < StandardError; end
    class LengthLimitExceededError < StandardError; end

    delegate :logger, to: Rails

    MAX_ATTEMPTS = 3

    Result = Data.define(
      :evaluation_data,
      :llm_response,
      :metrics,
    )

    MODEL = BedrockModels.model_id(:openai_gpt_oss_120b).freeze

    def self.call(...) = new(...).call

    def initialize(user_message:, tool:, system_prompt: nil)
      @user_message = user_message
      @tool = tool
      @system_prompt = system_prompt
    end

    def call
      start_time = Clock.monotonic_time
      client = Aws::BedrockRuntime::Client.new

      attempts = 0
      last_error = nil

      while attempts <= MAX_ATTEMPTS
        attempts += 1
        begin
          response = client.invoke_model(
            model_id: MODEL,
            body: {
              include_reasoning: false,
              messages: messages,
              tools: [tool],
              tool_choice: { type: "function", function: { name: tool.dig("function", "name") } },
              parallel_tool_calls: false,
              max_tokens: 15_000,
              temperature: 0.0,
            }.to_json,
          )
          parsed_response = JSON.parse(response.body.read)

          choice = parsed_response["choices"][0]

          raise LengthLimitExceededError if choice["finish_reason"] == "length"

          tool_call = choice.dig("message", "tool_calls", 0, "function", "arguments")
          raise MissingToolCallArgumentsError, "No tool call arguments returned in the LLM response." unless tool_call

          parsed_tool_output = JSON.parse(tool_call)
          validate_tool_output_against_schema(parsed_tool_output)

          return Result.new(
            evaluation_data: parsed_tool_output,
            llm_response: parsed_response,
            metrics: build_metrics(start_time, parsed_response),
          )
        rescue JSON::ParserError, JSON::Schema::ValidationError, MissingToolCallArgumentsError => e
          error_string = "#{e.class}, #{e.message}"
          full_error_message = "LLM did not return valid JSON that conformed to the schema. " \
                          "Attempt #{attempts}/#{MAX_ATTEMPTS}. Error: #{error_string}."

          if last_error.present? && error_string != last_error
            full_error_message += " This error is different from the previous error: #{last_error}."
          end

          logger.warn(full_error_message)

          if attempts >= MAX_ATTEMPTS
            raise InvalidToolCallError, "LLM did not return valid JSON that conformed to the schema " \
                                        "after #{MAX_ATTEMPTS} attempts. Error: #{error_string}"
          end

          last_error = error_string
          next
        end
      end
    end

  private

    attr_reader :user_message, :tool, :system_prompt

    def build_metrics(start_time, response)
      usage = response["usage"]
      {
        duration: Clock.monotonic_time - start_time,
        llm_prompt_tokens: usage["prompt_tokens"],
        llm_completion_tokens: usage["completion_tokens"],
        llm_cached_tokens: usage.dig("prompt_tokens_details", "cached_tokens"),
        model: response["model"],
      }
    end

    def validate_tool_output_against_schema(tool_output)
      schema = tool.dig("function", "parameters")
      JSON::Validator.validate!(schema, tool_output)
    end

    def messages
      return [{ role: "user", content: [{ type: "text", text: user_message }] }] unless system_prompt

      [
        { role: "system", content: [{ type: "text", text: system_prompt }] },
        { role: "user", content: [{ type: "text", text: user_message }] },
      ]
    end
  end
end
