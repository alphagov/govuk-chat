module Search
  class TextToEmbedding
    # TODO: confirm this model
    EMBEDDING_MODEL = "text-embedding-3-small".freeze
    INPUT_TOKEN_LIMIT = 8191
    BATCH_SIZE = 50

    def self.call(...) = new(...).call

    def initialize(single_or_collection_of_text)
      @string_input = single_or_collection_of_text.is_a?(String)
      @text_collection = Array(single_or_collection_of_text)
    end

    def call
      to_embed = text_collection.map(&method(:keep_input_within_token_limit))

      embeddings = convert_text_to_embeddings(to_embed)

      # return just first embedding rather than an array of embeddings if we
      # weren't given an array input
      string_input ? embeddings.first : embeddings
    end

  private

    attr_reader :string_input, :text_collection

    def openai_client
      @openai_client ||= OpenAIClient.build
    end

    def keep_input_within_token_limit(text)
      as_tokens = token_encoder.encode(text)

      return text if as_tokens.length <= INPUT_TOKEN_LIMIT

      token_encoder.decode(as_tokens[...INPUT_TOKEN_LIMIT])
    end

    def convert_text_to_embeddings(to_embed_collection)
      batches = to_embed_collection.each_slice(BATCH_SIZE).to_a

      batches.flat_map do |batch|
        response = openai_client.embeddings(
          parameters: { model: EMBEDDING_MODEL, input: batch },
        )

        response["data"].map { |data| data["embedding"] }
      end
    end

    def token_encoder
      @token_encoder ||= Tiktoken.encoding_for_model(EMBEDDING_MODEL)
    end
  end
end
