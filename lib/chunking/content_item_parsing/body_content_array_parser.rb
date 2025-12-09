module Chunking::ContentItemParsing
  class BodyContentArrayParser < BaseParser
    def call
      content = details_field!("body")

      html = extract_html_from_multiple_content_types!(content)

      build_chunks(html)
    end

    def self.non_indexable_content_item_reason(content_item)
      schema_name = content_item["schema_name"]
      schema_config = document_types_by_schema[schema_name]

      raise "#{schema_name} cannot be parsed by #{name}" if schema_config.parser != name

      document_type = content_item["document_type"]
      return if schema_config.document_types.keys.include?(document_type)

      "document type: #{document_type} not supported for schema: #{schema_name}"
    end
  end
end
