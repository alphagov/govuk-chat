module Chunking
  class ContentItemToChunks
    def self.call(content_item)
      unless supported_content_item?(content_item)
        raise "Content item not supported for parsing: #{non_indexable_content_item_reason(content_item)}"
      end

      parser_class(content_item["schema_name"]).call(content_item)
    end

    def self.supported_content_item?(content_item)
      non_indexable_content_item_reason(content_item).nil?
    end

    def self.non_indexable_content_item_reason(content_item)
      schema_name = content_item["schema_name"]

      return "#{schema_name} is not a supported schema" unless supported_schema?(schema_name)

      parser = parser_class(schema_name)

      return unless parser.respond_to?(:non_indexable_content_item_reason)

      parser.non_indexable_content_item_reason(content_item)
    end

    def self.supported_schema?(schema_name)
      Rails.configuration.search.document_types_by_schema[schema_name].present?
    end

    def self.parser_class(schema_name)
      Rails.configuration.search.document_types_by_schema.fetch(schema_name).parser.constantize
    end
  end
end
