module Search
  class ResultsForQuestion
    attr_reader :question_message

    def self.call(question_message)
      min_score = Rails.configuration.search.thresholds.minimum_score
      max_results = Rails.configuration.search.thresholds.max_results
      max_chunks = Rails.configuration.search.thresholds.retrieved_from_index

      metrics = {}
      embedding_start_time = Clock.monotonic_time
      embedding = Search::TextToEmbedding.call(question_message)
      metrics[:embedding_duration] = Clock.monotonic_time - embedding_start_time

      search_start_time = Clock.monotonic_time
      results = ChunkedContentRepository.new.search_by_embedding(
        embedding,
        max_chunks:,
      )
      metrics[:search_duration] = Clock.monotonic_time - search_start_time
      metrics[:embedding_provider] = Rails.configuration.embedding_provider

      reranking_start_time = Clock.monotonic_time
      weighted_results = Search::ResultsForQuestion::Reranker.call(results)
      results = weighted_results.select { |r| r.weighted_score >= min_score }.take(max_results)
      rejected_results = weighted_results - results
      metrics[:reranking_duration] = Clock.monotonic_time - reranking_start_time

      Search::ResultsForQuestion::ResultSet.new(results:, rejected_results:, metrics:)
    end
  end
end
