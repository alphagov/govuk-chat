module Search
  class ResultsForQuestion
    class Result < SimpleDelegator
      attr_reader :reranked_score

      def initialize(result:, reranked_score:)
        super(result)
        @reranked_score = reranked_score
      end
    end
  end
end
