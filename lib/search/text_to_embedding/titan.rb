class Search::TextToEmbedding
  class Titan
    INPUT_TEXT_LENGTH_LIMIT = 50_000

    def self.call(...) = new(...).call

    def initialize(single_or_collection_of_text)
      @string_input = single_or_collection_of_text.is_a?(String)
      @text_collection = Array(single_or_collection_of_text)
    end

    def call
      # For strings longer than the embedding model limit we have to truncate
      # the text.
      # This is done silently and in future we may want to log this in a
      # database or log a warning.
      to_embed = text_collection.map(&method(:keep_input_within_text_limit))

      embeddings = convert_text_to_embeddings(to_embed)

      # return just first embedding rather than an array of embeddings if we
      # weren't given an array input
      string_input ? embeddings.first : embeddings
    end

  private

    attr_reader :string_input, :text_collection

    def bedrock_client
      @bedrock_client ||= Aws::BedrockRuntime::Client.new
    end

    def keep_input_within_text_limit(text)
      text[0...INPUT_TEXT_LENGTH_LIMIT]
    end

    def convert_text_to_embeddings(to_embed_collection)
      to_embed_collection.map do |text|
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
end
