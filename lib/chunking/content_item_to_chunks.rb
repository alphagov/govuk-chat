module Chunking
  class ContentItemToChunks
    PARSERS_FOR_SCHEMAS = [
      ContentItemParsing::BodyContentArrayParser,
      ContentItemParsing::BodyContentParser,
      ContentItemParsing::PartsContentParser,
      ContentItemParsing::StepByStepNavParser,
      ContentItemParsing::TransactionParser,
    ].freeze

    def self.call(content_item)
      unless supported_content_item?(content_item)
        raise "Content item not supported for parsing: #{non_indexable_content_item_reason(content_item)}"
      end

      parser_class = parsers_by_schema_name[content_item["schema_name"]]
      parser_class.call(content_item)
    end

    def self.supported_content_item?(content_item)
      non_indexable_content_item_reason(content_item).nil?
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
