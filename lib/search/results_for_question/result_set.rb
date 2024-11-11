module Search
  class ResultsForQuestion
    ResultSet = Data.define(:results, :rejected_results, :metrics) do
      def self.empty
        new(results: [], rejected_results: [], metrics: {})
      end

      def empty?
        results.empty? && rejected_results.empty?
      end
    end
  end
end
