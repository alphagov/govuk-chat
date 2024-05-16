module Chunking
  class ContentItemToChunks
    PARSERS_FOR_SCHEMAS = [
      ContentItemParsing::BodyContentArrayParser,
      ContentItemParsing::BodyContentParser,
      ContentItemParsing::PartsContentParser,
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

    def self.non_indexable_content_item_reason(content_item)
      schema_name = content_item["schema_name"]
      parser = parsers_by_schema_name[schema_name]

      return "#{schema_name} is not a supported schema" if parser.nil?
      return unless parser.respond_to?(:non_indexable_content_item_reason)

      parser.non_indexable_content_item_reason(content_item)
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
