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

      invalid_document_type_reason(content_item)
    end

    def self.supported_schema?(schema_name)
      Rails.configuration.search.document_types_by_schema[schema_name].present?
    end

    def self.invalid_document_type_reason(content_item)
      schema_name = content_item["schema_name"]
      document_type = content_item["document_type"]
      schema_config = Rails.configuration.search.document_types_by_schema[schema_name]
      document_type_config = schema_config.document_types[document_type]

      if !schema_config.document_types.keys.include?(document_type)
        "document type: #{document_type} not supported for schema: #{schema_name}"
      elsif document_type_config&.requires_parent_document_type.present?
        parent_document_type = content_item.dig("expanded_links", "parent", 0, "document_type")
        return "content item lacks a parent document_type" unless parent_document_type

        return if document_type_config.requires_parent_document_type.keys.include?(parent_document_type)

        "#{schema_name} items with parent document type: #{parent_document_type} are not supported"
      end
    end

    def self.parser_class(schema_name)
      Rails.configuration.search.document_types_by_schema.fetch(schema_name).parser.constantize
    end
  end
end
