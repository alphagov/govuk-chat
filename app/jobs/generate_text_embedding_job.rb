class GenerateTextEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    repository = Search::ChunkedContentRepository.new

    begin
      result = repository.chunk(document_id)
    rescue Search::ChunkedContentRepository::NotFound
      Rails.logger.info("Document #{document_id} not found in the index.")
      return
    end

    embedding = Search::TextToEmbedding.call(result.plain_content, llm_provider: :titan)

    result = repository.update_document(document_id, { titan_embedding: embedding })

    if %i[created updated].include?(result)
      Rails.logger.info("Successfully indexed document #{document_id} with new embedding.")
    else
      Rails.logger.info("Failed to index document #{document_id}: unexpected result #{result}.")
    end
  end
end
