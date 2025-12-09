module Search
  class ResultsForQuestion
    class Reranker
      DEFAULT_WEIGHTING = 1.0

      def self.call(...) = new(...).call

      def self.document_type_weighting(schema_name, document_type, parent_document_type: nil)
        document_types = Rails.configuration.search.document_types_by_schema.fetch(schema_name)["document_types"]
        document_type_config = document_types.fetch(document_type)

        if parent_document_type
          parent_document_config = document_type_config.fetch("requires_parent_document_type")
          parent_document_config.fetch(parent_document_type)&.fetch("weight") || DEFAULT_WEIGHTING
        else
          (document_type_config || {}).fetch("weight", DEFAULT_WEIGHTING)
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
                                 self.class.document_type_weighting(result.schema_name, result.document_type, parent_document_type: result.parent_document_type)
                               else
                                 self.class.document_type_weighting(result.schema_name, result.document_type)
                               end

        Search::ResultsForQuestion::WeightedResult.new(
          result:,
          weighted_score: result.score * document_type_weight,
        )
      end
    end
  end
end
