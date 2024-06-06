module Search
  class ResultsForQuestion
    class WeightedResult < SimpleDelegator
      attr_reader :weighted_score

      def initialize(result:, weighted_score:)
        super(result)
        @weighted_score = weighted_score
      end
    end
  end
end
