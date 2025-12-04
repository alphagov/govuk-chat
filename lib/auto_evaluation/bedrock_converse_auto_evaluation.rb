module AutoEvaluation
  class BedrockConverseAutoEvaluation
    Result = Data.define(
      :evaluation_data,
      :llm_response,
      :metrics,
    )

    MODEL = BedrockModels.model_id(:openai_gpt_oss_120b).freeze

    def self.call(...) = new(...).call

    def initialize(user_message)
      @user_message = user_message
    end

    def call
      start_time = Clock.monotonic_time
      bedrock_client = Aws::BedrockRuntime::Client.new
      llm_response = bedrock_client.converse(
        messages: [{ role: "user", content: [{ text: user_message }] }],
        model_id: MODEL,
        inference_config: {
          max_tokens: 4096,
          temperature: 0.0,
        },
      )

      Result.new(
        evaluation_data: parse_first_text_content_from_response(llm_response),
        llm_response: llm_response.to_h,
        metrics: build_metrics(start_time, llm_response),
      )
    end

  private

    attr_reader :user_message

    def parse_first_text_content_from_response(response)
      first_text_content_block = response.output.message.content.detect do |content_block|
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
        model: MODEL,
      }
    end
  end
end
