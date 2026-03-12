module Search
  class ResultsForQuestion
    ResultSet = Data.define(:opensearch_index, :results, :rejected_results, :metrics) do
      def self.empty
        new(opensearch_index: nil, results: [], rejected_results: [], metrics: {})
      end

      def empty?
        results.empty? && rejected_results.empty?
      end
    end
  end
end
