module Search
  class ResultsForQuestion
    class Reranker
      DOCUMENT_TYPE_WEIGHTINGS = Rails.configuration.search.document_type_weightings.to_h.freeze

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
                                 DOCUMENT_TYPE_WEIGHTINGS.fetch(result.parent_document_type, 1.0)
                               else
                                 DOCUMENT_TYPE_WEIGHTINGS.fetch(result.document_type, 1.0)
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
    end
  end
end
