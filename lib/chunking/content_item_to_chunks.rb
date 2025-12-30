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
      schema_config = Rails.configuration.search.document_types_by_schema[schema_name]
      return "#{schema_name} is not a supported schema" unless schema_config

      document_type = content_item["document_type"]
      return "document type: #{document_type} not supported for schema: #{schema_name}" unless schema_config.document_types.key?(document_type)

      document_type_config = schema_config.document_types[document_type]
      return unless document_type_config&.requires_parent_document_type

      parent_document_type = content_item.dig("expanded_links", "parent", 0, "document_type")
      return "content item lacks a parent document_type" unless parent_document_type

      supported_parent = document_type_config.requires_parent_document_type.keys.include?(parent_document_type)
      "#{schema_name} items with parent document type: #{parent_document_type} are not supported" unless supported_parent
    end

    def self.supported_schema?(schema_name)
      Rails.configuration.search.document_types_by_schema[schema_name].present?
    end

    def self.parser_class(schema_name)
      Rails.configuration.search.document_types_by_schema.fetch(schema_name).parser.constantize
    end
  end
end
