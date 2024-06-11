module Search
  class ResultsForQuestion
    ResultSet = Data.define(:results, :rejected_results) do
      def self.empty
        new(results: [], rejected_results: [])
      end

      def empty?
        results.empty? && rejected_results.empty?
      end
    end
  end
end
