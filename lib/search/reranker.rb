module Search
  class Reranker
    def self.call(...) = new(...).call

    def initialize(search_results)
      @search_results = search_results
    end

    def call
      results
    end

  private

    attr_reader :search_results

    def results
      search_results.map(&method(:rank_result)).sort_by { |r| -r.weighted_score }
    end

    def rank_result(result)
      document_type_weight = if result.document_type == "html_publication"
                               document_type_weight(result.parent_document_type)
                             else
                               document_type_weight(result.document_type)
                             end
      Search::ResultsForQuestion::WeightedResult.new(
        result:,
        weighted_score: result.score * document_type_weight,
      )
    end

    def score_threshold
      Rails.configuration.search.thresholds.minimum_score
    end

    def max_number_of_results
      Rails.configuration.search.thresholds.max_results
    end

    def document_type_weight(document_type)
      Rails.configuration.search.document_type_weightings.fetch(document_type, 1.0)
    end
  end
end
