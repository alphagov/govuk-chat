class Search::TextToEmbedding
  class Titan
    class InputTextTokenLimitExceededError < StandardError; end

    INPUT_TEXT_LENGTH_LIMIT = 50_000
    RETRY_COUNT = 5

    def self.call(...) = new(...).call

    def initialize(single_or_collection_of_text)
      @string_input = single_or_collection_of_text.is_a?(String)
      @text_collection = Array(single_or_collection_of_text)
    end

    def call
      embeddings = text_collection.map(&method(:convert_text_to_embeddings))

      # return just first embedding rather than an array of embeddings if we
      # weren't given an array input
      string_input ? embeddings.first : embeddings
    end

  private

    attr_reader :string_input, :text_collection

    def bedrock_client
      @bedrock_client ||= Aws::BedrockRuntime::Client.new
    end

    def convert_text_to_embeddings(text)
      # Titan has a limit of 50,000 characters or 8,192 tokens for the input text.
      # We have no way of knowing how many tokens the text will be, so we'll first
      # truncate the text to 50,000 characters as we know we can't exceed that limit.
      text = text[0...INPUT_TEXT_LENGTH_LIMIT]

      # Now we'll try to embed the text. If it fails due to exceeding the token limit,
      # we'll truncate the text further and try again, up to {RETRY_COUNT} times.
      tries = 0

      while tries < RETRY_COUNT
        text = text[0...(text.length * 0.8)] if tries.positive? # Truncate to 80% of the current length

        begin
          return generate_embedding(text)
        rescue Aws::BedrockRuntime::Errors::ValidationException => e
          unless e.message =~ /too many input tokens/i
            raise e
          end

          tries += 1

          if tries >= RETRY_COUNT
            raise(
              InputTextTokenLimitExceededError,
              "Failed to generate Titan embedding after #{RETRY_COUNT} attempts. #{e.message}",
            )
          end
        end
      end
    end

    def generate_embedding(text)
      response = bedrock_client.invoke_model(
        model_id: BedrockModels::TITAN_EMBED_V2,
        body: {
          inputText: text,
        }.to_json,
      )
      JSON.parse(response.body.read)["embedding"]
    end
  end
end
