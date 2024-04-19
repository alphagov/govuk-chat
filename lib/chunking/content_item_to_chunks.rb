module Chunking
  class ContentItemToChunks
    PARSERS_FOR_SCHEMAS = {
      ContentItemParsing::BodyContentParser => %w[answer
                                                  news_article],
      ContentItemParsing::GuideParser => %w[guide],
      ContentItemParsing::TransactionParser => %w[transaction],
      # TODO: establish all supported schemas and add parsers for them
    }.freeze

    def self.call(content_item)
      schema_name = content_item["schema_name"]
      parser_class = PARSERS_FOR_SCHEMAS.find { |_, v| v.include?(schema_name) }
                                        &.first

      raise "No content item parser configured for #{schema_name}" unless parser_class

      parser_class.call(content_item)
    end

    def self.supported_schema_and_document_type?(schema, _document_type)
      supported_schemas.include?(schema)
    end

    def self.supported_schemas
      PARSERS_FOR_SCHEMAS.values.flatten
    end
  end
end
