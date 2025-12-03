class BedrockConverseClient
  MODEL = "openai.gpt-oss-120b-1:0".freeze

  def self.converse(...) = new(...).converse

  def self.parse_first_text_content_from_response(bedrock_response)
    first_text_content_block = bedrock_response.output.message.content.detect do |content_block|
      content_block.is_a?(Aws::BedrockRuntime::Types::ContentBlock::Text)
    end

    JSON.parse(first_text_content_block.text)
  end

  def initialize(messages:, options: {})
    @messages = messages
    @options = options
  end

  def converse
    bedrock_client.converse(**request_args)
  end

private

  attr_reader :messages, :options

  def bedrock_client
    @bedrock_client ||= Aws::BedrockRuntime::Client.new
  end

  def request_args
    {
      model_id: MODEL,
      messages:,
      inference_config:,
    }.merge(options)
  end

  def inference_config
    {
      max_tokens: 4096,
      temperature: 0.0,
    }
  end
end
