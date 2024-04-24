module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    SCHEMAS_TO_DISALLOWED_DOCUMENT_TYPES = {
      "call_for_evidence" => [],
      "case_study" => [],
      "consultation" => [],
      "detailed_guide" => [],
      "help_page" => [],
      "hmrc_manual_section" => [],
      "history" => [],
      "manual" => [],
      "manual_section" => [],
      "news_article" => [],
      "publication" => %w[correspondence decision],
      "service_manual_guide" => [],
      "statistical_data_set" => [],
      "statistics_announcement" => [],
    }.freeze

    def call
      content = details_field!("body")

      html = if content.is_a?(Array)
               extract_html_from_multiple_content_types!(content)
             else
               content
             end

      build_chunks(html)
    end

    def self.supported_schema_and_document_type?(schema_name, document_type)
      disallowed_document_types = SCHEMAS_TO_DISALLOWED_DOCUMENT_TYPES[schema_name]
      return false unless disallowed_document_types

      disallowed_document_types.exclude?(document_type)
    end

    def self.allowed_schemas
      SCHEMAS_TO_DISALLOWED_DOCUMENT_TYPES.keys
    end
  end
end
