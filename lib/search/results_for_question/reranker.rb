module Search
  class ResultsForQuestion
    class Reranker
      DEFAULT_WEIGHTING = 1.0

      def self.call(...) = new(...).call

      def self.document_type_weighting(schema_name, document_type, parent_document_type: nil)
        document_type_config = Rails.configuration.search.document_types_by_schema.dig(schema_name, "document_types", document_type) || {}

        parent_document_type_config = document_type_config.dig("requires_parent_document_type", parent_document_type) || {}

        parent_document_type_config["weight"] || document_type_config["weight"] || DEFAULT_WEIGHTING
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
        document_type_weight = self.class.document_type_weighting(result.schema_name, result.document_type, parent_document_type: result.parent_document_type)

        Search::ResultsForQuestion::WeightedResult.new(
          result:,
          weighted_score: result.score * document_type_weight,
          weighting: document_type_weight,
        )
      end
    end
  end
end
