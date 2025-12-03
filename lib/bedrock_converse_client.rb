class BedrockConverseClient
  MODEL = "openai.gpt-oss-120b-1:0".freeze

  def self.converse(...) = new(...).converse

  def self.parse_first_text_content_from_response(bedrock_response)
    first_text_content_block = bedrock_response.output.message.content.detect do |content_block|
      content_block.is_a?(Aws::BedrockRuntime::Types::ContentBlock::Text)
    end

    JSON.parse(first_text_content_block.text)
  end

  def initialize(user_message)
    @user_message = user_message
  end

  def converse
    bedrock_client.converse(
      messages: [{ role: "user", content: [{ text: user_message }] }],
      model_id: MODEL,
      inference_config: {
        max_tokens: 4096,
        temperature: 0.0,
      },
    )
  end

private

  attr_reader :user_message

  def bedrock_client
    @bedrock_client ||= Aws::BedrockRuntime::Client.new
  end
end
