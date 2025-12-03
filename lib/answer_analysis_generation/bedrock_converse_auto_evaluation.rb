module AnswerAnalysisGeneration
  class BedrockConverseAutoEvaluation
    Result = Data.define(
      :eval_data,
      :llm_response,
      :metrics,
    )

    MODEL = "openai.gpt-oss-120b-1:0".freeze

    def self.call(...) = new(...).call(...)

    def initialize(user_message)
      @user_message = user_message
    end

    def call
      start_time = Clock.monotonic_time
      bedrock_client = Aws::BedrockRuntime::Client.new
      response = bedrock_client.converse({
        model_id: MODEL,
        messages: [{ "role": "user", "content": [{ "text": user_message }] }],
        inference_config: { max_tokens: 4096, temperature: 0.0 },
      })

      Result.new(
        eval_data: parse_first_text_content_from_response(response),
        llm_response: response.to_h,
        metrics: build_metrics(start_time, response),
      )
    end

  private

    attr_reader :user_message

    def parse_first_text_content_from_response(bedrock_response)
      first_text_content_block = bedrock_response.output.message.content.detect do |content_block|
        content_block.is_a?(Aws::BedrockRuntime::Types::ContentBlock::Text)
      end

      JSON.parse(first_text_content_block.text)
    end

    def build_metrics(start_time, response)
      {
        duration: Clock.monotonic_time - start_time,
        llm_prompt_tokens: BedrockModels.claude_total_prompt_tokens(response[:usage]),
        llm_completion_tokens: response[:usage][:output_tokens],
        llm_cached_tokens: response[:usage][:cache_read_input_tokens],
        model: response[:model],
      }
    end
  end
end
