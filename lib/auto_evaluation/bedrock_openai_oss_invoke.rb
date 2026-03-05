module AutoEvaluation
  class BedrockOpenAIOssInvoke
    class InvalidToolCallSchemaError < StandardError; end
    class LengthLimitExceededError < StandardError; end

    Result = Data.define(
      :evaluation_data,
      :llm_response,
      :metrics,
    )

    MODEL = BedrockModels.model_id(:openai_gpt_oss_120b).freeze

    def self.call(...) = new(...).call

    def initialize(user_message, tools, system_prompt = nil)
      @user_message = user_message
      @tools = tools
      @system_prompt = system_prompt
    end

    def call
      start_time = Clock.monotonic_time
      client = Aws::BedrockRuntime::Client.new
      response = client.invoke_model(
        model_id: MODEL,
        body: {
          include_reasoning: false,
          messages:,
          tools:,
          tool_choice: "required",
          parallel_tool_calls: false,
          max_tokens: 15_000,
          temperature: 0.0,
        }.to_json,
      )
      parsed_response = JSON.parse(response.body.read)

      choice = parsed_response["choices"][0]

      raise LengthLimitExceededError if choice["finish_reason"] == "length"

      parsed_tool_output = JSON.parse(
        choice["message"]["tool_calls"][0]["function"]["arguments"],
      )

      validate_tool_output_against_schema(parsed_tool_output)

      Result.new(
        evaluation_data: parsed_tool_output,
        llm_response: parsed_response,
        metrics: build_metrics(start_time, parsed_response),
      )
    end

  private

    attr_reader :user_message, :tools, :system_prompt

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
      schema = tools.dig(0, "function", "parameters")
      JSON::Validator.validate!(schema, tool_output)
    rescue JSON::Schema::ValidationError => e
      raise InvalidToolCallSchemaError, "Tool call response does not match schema: #{e.message}"
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
