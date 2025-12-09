module Search
  class ResultsForQuestion
    class Reranker
      def self.call(...) = new(...).call

      def self.document_type_weightings
        @document_type_weightings ||= begin
          schemas = Rails.configuration.search.document_types_by_schema
          schemas.each_with_object({}) do |(_, config), memo|
            config["document_types"].each do |doc_type, config|
              memo[doc_type] = config["weight"] if config && config["weight"]
            end
          end
        end
      end

      def initialize(search_results)
        @search_results = search_results
      end

      def call
        search_results.map(&method(:weight_result)).sort_by { |r| -r.weighted_score }
      end

    private

      attr_reader :search_results

      def weight_result(result)
        document_type_weight = if result.document_type == "html_publication"
                                 self.class.document_type_weightings.fetch(result.parent_document_type, 1.0)
                               else
                                 self.class.document_type_weightings.fetch(result.document_type, 1.0)
                               end
        Search::ResultsForQuestion::WeightedResult.new(
          result:,
          weighted_score: result.score * document_type_weight,
        )
      end
    end
  end
end
