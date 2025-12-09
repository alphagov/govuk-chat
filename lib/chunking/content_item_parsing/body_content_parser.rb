module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    def call
      content = details_field!("body")

      build_chunks(content)
    end

    def self.non_indexable_content_item_reason(content_item)
      schema_name = content_item["schema_name"]
      schema_config = document_types_by_schema[schema_name]

      raise "#{schema_name} cannot be parsed by #{name}" if schema_config.parser != name

      document_type = content_item["document_type"]
      return not_supported_html_publication_reason(content_item) if schema_name == "html_publication"
      return if schema_config.document_types.keys.include?(document_type)

      "document type: #{document_type} not supported for schema: #{schema_name}"
    end

    def self.not_supported_html_publication_reason(content_item)
      parent_document_type = content_item&.dig("expanded_links", "parent", 0, "document_type")

      return "HTML publication lacks a parent document_type" unless parent_document_type

      schema_config = document_types_by_schema["html_publication"]

      return if schema_config.document_types.keys.include?(parent_document_type)

      "html_publication items with parent document type: #{parent_document_type} are not supported"
    end
    private_class_method :not_supported_html_publication_reason
  end
end
