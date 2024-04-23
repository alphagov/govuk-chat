module Chunking
  class ContentItemToChunks
    PARSERS_FOR_SCHEMAS = [
      ContentItemParsing::BodyContentParser,
      ContentItemParsing::GuideParser,
      ContentItemParsing::TransactionParser,
      # TODO: establish all supported schemas and add parsers for them
    ].freeze

    def self.call(content_item)
      schema_name = content_item["schema_name"]
      parser_class = parser_map[schema_name]

      raise "No content item parser configured for #{schema_name}" unless parser_class

      parser_class.call(content_item)
    end

    def self.supported_schema_and_document_type?(schema_name, document_type)
      parser = parser_map[schema_name]

      return false if parser.nil?

      parser.supported_schema_and_document_type?(schema_name, document_type)
    end

    def self.parser_map
      parser_list = []
      PARSERS_FOR_SCHEMAS.each do |parser|
        parser_list += parser::ALLOWED_SCHEMAS.map { |schema| [schema, parser] }
      end
      parser_list.to_h
    end

    def self.supported_schemas
      parser_map.keys
    end
  end
end
