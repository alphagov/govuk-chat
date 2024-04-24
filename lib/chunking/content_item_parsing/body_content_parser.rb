module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    SCHEMAS_TO_DOCUMENT_CHECK = {
      "answer" => ->(_) { true },
      "call_for_evidence" => ->(_) { true },
      "case_study" => ->(_) { true },
      "consultation" => ->(_) { true },
      "detailed_guide" => ->(_) { true },
      "help_page" => ->(_) { true },
      "hmrc_manual_section" => ->(_) { true },
      "history" => ->(_) { true },
      "manual" => ->(_) { true },
      "manual_section" => ->(_) { true },
      "news_article" => ->(_) { true },
      "publication" => ->(document_type) { %w[correspondence decision].exclude?(document_type) },
      "service_manual_guide" => ->(_) { true },
      "statistical_data_set" => ->(_) { true },
      "statistics_announcement" => ->(_) { true },
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
      document_type_check = SCHEMAS_TO_DOCUMENT_CHECK[schema_name]
      return false unless document_type_check

      document_type_check.call(document_type)
    end

    def self.allowed_schemas
      SCHEMAS_TO_DOCUMENT_CHECK.keys
    end
  end
end
