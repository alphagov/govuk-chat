module AutoEvaluation
  class BedrockOpenAIOssInvoke
    Result = Data.define(
      :evaluation_data,
      :llm_response,
      :metrics,
    )

    MODEL = BedrockModels.model_id(:openai_gpt_oss_120b).freeze

    def self.call(...) = new(...).call

    def initialize(user_message, json_schema)
      @user_message = user_message
      @json_schema = json_schema
    end

    def call
      start_time = Clock.monotonic_time
      client = Aws::BedrockRuntime::Client.new
      response = client.invoke_model(
        model_id: MODEL,
        body: {
          include_reasoning: false,
          messages: [
            { role: "user", content: [{ type: "text", text: user_message }] },
          ],
          response_format: {
            type: "json_schema",
            json_schema:,
          },
          max_tokens: 4096,
          temperature: 0.0,
        }.to_json,
      )
      parsed_response = JSON.parse(response.body.read)
      corrected_json = resolve_bedrock_openai_oss_json(
        parsed_response["choices"][0]["message"]["content"],
      )
      parsed_structured_output = JSON.parse(corrected_json)

      Result.new(
        evaluation_data: parsed_structured_output,
        llm_response: parsed_response,
        metrics: build_metrics(start_time, parsed_response),
      )
    end

  private

    attr_reader :user_message, :json_schema

    def build_metrics(start_time, response)
      {
        duration: Clock.monotonic_time - start_time,
        llm_prompt_tokens: response["usage"]["prompt_tokens"],
        llm_completion_tokens: response["usage"]["completion_tokens"],
        llm_cached_tokens: nil,
        model: response["model"],
      }
    end

    def resolve_bedrock_openai_oss_json(json_string)
      # Bedrock adds an extra curly brace at the start of the structured output
      # which causes JSON parsing to fail. This removes the double opening brace
      # with and without newlines.
      json_string.gsub(/\A\{\s*\{/, "{")
    end
  end
end
