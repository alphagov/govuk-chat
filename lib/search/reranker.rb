module Search
  class Reranker
    def self.call(...) = new(...).call

    def initialize(search_results)
      @search_results = search_results
    end

    def call
      Search::ResultsForQuestion::ResultSet.new(results:, rejected_results:)
    end

  private

    attr_reader :search_results

    def results
      ranked_results.select { |r| r.reranked_score >= score_threshold }.sort_by { |r| -r.reranked_score }.take(max_number_of_results)
    end

    def rejected_results
      ranked_results - results
    end

    def ranked_results
      @ranked_results ||= search_results.map(&method(:rank_result))
    end

    def rank_result(result)
      document_type_weight = if result.document_type == "html_publication"
                               Reranking::DocumentTypeWeights.call(result.parent_document_type)
                             else
                               Reranking::DocumentTypeWeights.call(result.document_type)
                             end
      Search::ResultsForQuestion::Result.new(
        result:,
        reranked_score: result.score * document_type_weight,
      )
    end

    def score_threshold
      Rails.configuration.search.result_score_threshold
    end

    def max_number_of_results
      Rails.configuration.search.max_number_of_results
    end
  end
end
