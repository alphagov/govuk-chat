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
        Search::ResultsForQuestion::Reranker.document_type_weighting(schema_name, document_type, parent_document_type:)
      end
    end
  end
end
