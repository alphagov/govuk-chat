module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    EXCLUDED_PUBLICATION_DOCUMENT_TYPES = %w[correspondence decision].freeze
    SCHEMAS_TO_DOCUMENT_TYPE_CHECK = {
      "call_for_evidence" => ANY_DOCUMENT_TYPE,
      "case_study" => ANY_DOCUMENT_TYPE,
      "consultation" => ANY_DOCUMENT_TYPE,
      "corporate_information_page" => ANY_DOCUMENT_TYPE,
      "worldwide_corporate_information_page" => ANY_DOCUMENT_TYPE,
      "detailed_guide" => ANY_DOCUMENT_TYPE,
      "hmrc_manual_section" => ANY_DOCUMENT_TYPE,
      "html_publication" => ->(parent_document_type) { EXCLUDED_PUBLICATION_DOCUMENT_TYPES.exclude?(parent_document_type) },
      "history" => ANY_DOCUMENT_TYPE,
      "news_article" => ANY_DOCUMENT_TYPE,
      "organisation" => ANY_DOCUMENT_TYPE,
      "publication" => ->(document_type) { EXCLUDED_PUBLICATION_DOCUMENT_TYPES.exclude?(document_type) },
      "service_manual_guide" => ANY_DOCUMENT_TYPE,
      "speech" => ->(document_type) { %w[oral_statement written_statement].include?(document_type) },
      "statistical_data_set" => ANY_DOCUMENT_TYPE,
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
