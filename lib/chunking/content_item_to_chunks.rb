module Chunking
  class ContentItemToChunks
    PARSERS_FOR_SCHEMAS = [
      ContentItemParsing::BodyContentArrayParser,
      ContentItemParsing::BodyContentParser,
      ContentItemParsing::GuideParser,
      ContentItemParsing::TransactionParser,
      # TODO: establish all supported schemas and add parsers for them
    ].freeze

    def self.call(content_item)
      schema_name = content_item["schema_name"]
      document_type = content_item["document_type"]

      unless supported_schema_and_document_type?(schema_name, document_type)
        raise "schema #{schema_name} with document_type #{document_type} is not supported for parsing"
      end

      parser_class = parsers_by_schema_name[schema_name]
      parser_class.call(content_item)
    end

    def self.supported_schema_and_document_type?(schema_name, document_type)
      parser = parsers_by_schema_name[schema_name]

      return false if parser.nil?

      parser.supported_schema_and_document_type?(schema_name, document_type)
    end

    def self.parsers_by_schema_name
      parser_list = []
      PARSERS_FOR_SCHEMAS.each do |parser|
        parser_list += parser.allowed_schemas.map { |schema| [schema, parser] }
      end
      parser_list.to_h
    end
  end
end
