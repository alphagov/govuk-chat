module Search
  class ResultsForQuestion
    class Reranker
      DEFAULT_WEIGHTING = 1.0

      def self.call(...) = new(...).call

      def initialize(search_results)
        @search_results = search_results
      end

      def call
        search_results.map(&method(:weight_result)).sort_by { |r| -r.weighted_score }
      end

    private

      attr_reader :search_results

      def weight_result(result)
        document_type_weight = document_type_weighting(result.schema_name, result.document_type, parent_document_type: result.parent_document_type)

        Search::ResultsForQuestion::WeightedResult.new(
          result:,
          weighted_score: result.score * document_type_weight,
          weighting: document_type_weight,
        )
      end

      def document_type_weighting(schema_name, document_type, parent_document_type: nil)
        document_type_config = document_type_config_for(schema_name, document_type) || {}

        parent_document_type_config = document_type_config.dig("requires_parent_document_type", parent_document_type) || {}

        parent_document_type_config["weight"] || document_type_config["weight"] || DEFAULT_WEIGHTING
      end

      def document_type_config_for(schema_name, document_type)
        return document_type_config_for_nil_schema(document_type) if schema_name.nil?

        schemas_config = Rails.configuration.search.document_types_by_schema

        schema_config = schemas_config[schema_name]
        if schema_config.nil?
          Rails.logger.warn(
            "Search::ResultsForQuestion::Reranker: schema_name=#{schema_name.inspect} not configured in search.document_types_by_schema",
          )
          return nil
        end

        document_types = schema_config["document_types"].to_h
        unless document_types.key?(document_type)
          Rails.logger.warn(
            "Search::ResultsForQuestion::Reranker: no document type config for schema_name=#{schema_name.inspect} " \
            "document_type=#{document_type.inspect}",
          )
          return nil
        end

        document_types[document_type]
      end

      def document_type_config_for_nil_schema(document_type)
        schemas_config = Rails.configuration.search.document_types_by_schema
        candidate_schema_name, schema_config = schemas_config.find do |_, candidate_schema_config|
          candidate_schema_config.fetch("document_types", {}).key?(document_type)
        end

        if candidate_schema_name
          Rails.logger.warn(
            "Search::ResultsForQuestion::Reranker: nil schema_name for document_type=#{document_type.inspect}; " \
            "falling back to schema_name=#{candidate_schema_name.inspect}",
          )

          return schema_config.dig("document_types", document_type)
        end

        Rails.logger.warn(
          "Search::ResultsForQuestion::Reranker: nil schema_name for document_type=#{document_type.inspect}; " \
          "no matching document type config found",
        )
        nil
      end
    end
  end
end
