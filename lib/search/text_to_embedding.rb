module Search
  class TextToEmbedding
    # TODO: confirm this model
    EMBEDDING_MODEL = "text-embedding-3-small".freeze
    INPUT_TOKEN_LIMIT = 8191
    ROUGH_ALLOWED_TOKENS = (INPUT_TOKEN_LIMIT * 0.9).round # 90% of token limit

    def self.call(...) = new(...).call

    def initialize(single_or_collection_of_text)
      @string_input = single_or_collection_of_text.is_a?(String)
      @text_collection = Array(single_or_collection_of_text)
    end

    def call
      embeddings = group_text_into_batches.flat_map do |batch|
        response = openai_client.embeddings(
          parameters: { model: EMBEDDING_MODEL, input: batch },
        )

        response["data"].map { |data| data["embedding"] }
      end

      # return just first embedding rather than an array of embeddings if we
      # weren't given an array input
      string_input ? embeddings.first : embeddings
    end

  private

    attr_reader :string_input, :text_collection

    # Converts an array of strings into an array that contains groups of strings.
    # Where each group of strings represent a batch that are within the token
    # limit and can be processed to embeddings in one request.
    def group_text_into_batches
      # we can skip the batching maths if there is only one item
      return [text_collection] if text_collection.length == 1

      rough_token_counts = text_collection.index_with do |text|
        OpenAI.rough_token_count(text)
      end

      text_collection.each_with_object([]) do |text, batches|
        text_tokens = rough_token_counts[text]

        empty_batch = batches.last.nil?

        if empty_batch || text_tokens > ROUGH_ALLOWED_TOKENS
          batches.append([text])
          next
        end

        tokens_used_in_batch = batches.last.inject(0) do |memo, batch_text|
          memo + rough_token_counts[batch_text]
        end

        if (tokens_used_in_batch + text_tokens) > ROUGH_ALLOWED_TOKENS
          batches.append([text]) # create a new batch
        else
          batches.last.append(text) # add to batch
        end
      end
    end

    def openai_client
      # TODO: replace with OpenAIClient.new once https://github.com/alphagov/govuk-chat/pull/84 is merged
      @openai_client ||= OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"))
    end
  end
end
