class BedrockConverseClient
  Result = Data.define(
    :text_content,
    :llm_response,
  )

  MODEL = "openai.gpt-oss-120b-1:0".freeze
  MAX_RETRIES = 3

  delegate :logger, to: Rails

  def self.converse(...) = new(...).converse

  def initialize(user_message)
    @user_message = user_message
  end

  def converse
    retry_count = 0

    begin
      llm_response = bedrock_client.converse(
        messages: [{ role: "user", content: [{ text: user_message }] }],
        model_id: MODEL,
        inference_config: {
          max_tokens: 4096,
          temperature: 0.0,
        },
      )

      Result.new(
        text_content: parse_first_text_content_from_response(llm_response),
        llm_response:,
      )
    rescue JSON::ParserError => e
      raise e if retry_count >= MAX_RETRIES

      retry_count += 1
      logger.warn("LLM returned invalid JSON, retrying #{retry_count}/#{MAX_RETRIES}: #{e.message}")
      retry
    end
  end

private

  attr_reader :user_message

  def bedrock_client
    @bedrock_client ||= Aws::BedrockRuntime::Client.new
  end

  def parse_first_text_content_from_response(bedrock_response)
    first_text_content_block = bedrock_response.output.message.content.detect do |content_block|
      content_block.is_a?(Aws::BedrockRuntime::Types::ContentBlock::Text)
    end

    JSON.parse(first_text_content_block.text)
  end
end
