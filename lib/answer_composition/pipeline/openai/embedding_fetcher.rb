module AnswerComposition
  module Pipeline
    module OpenAI
      class EmbeddingFetcher
        def self.call(question:, **_opts)
          embeddings = OpenAI.client.embeddings(
            parameters: { model: "text-embedding-3-small", input: question.message },
          )

          question.embedding = embeddings.dig("data", 0, "embedding")
          question
        end
      end
    end
  end
end
