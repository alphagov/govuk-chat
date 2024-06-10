module Search
  class ResultsForQuestion
    class WeightedResult < SimpleDelegator
      attr_reader :weighted_score

      def initialize(result:, weighted_score:)
        super(result)
        @weighted_score = weighted_score
      end

      def score_calculation
        "#{score} * #{weighting} = #{weighted_score}"
      end

    private

      def weighting
        Search::ResultsForQuestion::Reranker::DOCUMENT_TYPE_WEIGHTINGS.fetch(document_type, 1.0)
      end
    end
  end
end
