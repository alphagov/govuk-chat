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

      def chunk_uid
        "#{content_id}_#{locale}_#{chunk_index}_#{digest}"
      end

      def as_json(...)
        to_h.merge(
          "weighted_score" => weighted_score,
          "weighting" => weighting,
          "chunk_uid" => chunk_uid,
        ).as_json(...)
      end
    end
  end
end
