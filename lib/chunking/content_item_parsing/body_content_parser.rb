module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    ALLOWED_PUBLICATION_DOCUMENT_TYPES = %w[form
                                            guidance
                                            notice
                                            promotional
                                            regulation
                                            statutory_guidance].freeze
    INCLUDED_CORPORATE_INFORMATION_TYPES = %w[about complaints_procedure modern_slavery_statement].freeze
    SCHEMAS_TO_DOCUMENT_TYPE_CHECK = {
      "corporate_information_page" => ->(document_type) { INCLUDED_CORPORATE_INFORMATION_TYPES.include?(document_type) },
      "worldwide_corporate_information_page" => ->(document_type) { INCLUDED_CORPORATE_INFORMATION_TYPES.include?(document_type) },
      "detailed_guide" => ANY_DOCUMENT_TYPE,
      "html_publication" => ->(parent_document_type) { ALLOWED_PUBLICATION_DOCUMENT_TYPES.include?(parent_document_type) },
      "organisation" => ANY_DOCUMENT_TYPE,
      "publication" => ->(document_type) { ALLOWED_PUBLICATION_DOCUMENT_TYPES.include?(document_type) },
      "service_manual_guide" => ANY_DOCUMENT_TYPE,
      "take_part" => ANY_DOCUMENT_TYPE,
      "worldwide_organisation" => ANY_DOCUMENT_TYPE,
    }.freeze

    def call
      content = details_field!("body")

      build_chunks(content)
    end

    def self.non_indexable_content_item_reason(content_item)
      schema_name = content_item["schema_name"]
      document_type_check = SCHEMAS_TO_DOCUMENT_TYPE_CHECK[schema_name]

      document_type = content_item["document_type"]
      return not_supported_html_publication_reason(content_item) if schema_name == "html_publication"
      return if document_type_check&.call(document_type)

      "document type: #{document_type} not supported for schema: #{schema_name}"
    end

    def self.not_supported_html_publication_reason(content_item)
      parent_document_type = content_item&.dig("expanded_links", "parent", 0, "document_type")

      return "HTML publication lacks a parent document_type" unless parent_document_type

      document_type_check = SCHEMAS_TO_DOCUMENT_TYPE_CHECK["html_publication"]

      return if document_type_check.call(parent_document_type)

      "html_publication items with parent document type: #{parent_document_type} are not supported"
    end
    private_class_method :not_supported_html_publication_reason

    def self.allowed_schemas
      SCHEMAS_TO_DOCUMENT_TYPE_CHECK.keys
    end
  end
end
