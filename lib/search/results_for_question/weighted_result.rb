module Search
  class ResultsForQuestion
    class WeightedResult < SimpleDelegator
      attr_reader :weighted_score, :weighting

      def initialize(result:, weighted_score:, weighting:)
        super(result)
        @weighted_score = weighted_score
        @weighting = weighting
      end

      def score_calculation
        "#{score} * #{weighting} = #{weighted_score}"
      end
    end
  end
end
