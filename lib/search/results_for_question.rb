module Search
  class ResultsForQuestion
    attr_reader :question_message

    def self.call(question_message)
      min_score = Rails.configuration.search.thresholds.minimum_score
      max_results = Rails.configuration.search.thresholds.max_results

      embedding = Search::TextToEmbedding.call(question_message)
      results = ChunkedContentRepository.new.search_by_embedding(embedding)
      weighted_results = Search::ResultsForQuestion::Reranker.call(results)
      results = weighted_results.select { |r| r.weighted_score >= min_score }.take(max_results)
      rejected_results = weighted_results - results
      Search::ResultsForQuestion::ResultSet.new(results:, rejected_results:)
    end
  end
end
