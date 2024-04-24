module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    DISALLOWED_DOCUMENT_TYPES = %w[correspondence decision].freeze

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
      allowed_schemas.include?(schema_name) && DISALLOWED_DOCUMENT_TYPES.exclude?(document_type)
    end

    def self.allowed_schemas
      %w[call_for_evidence
         case_study
         consultation
         detailed_guide
         help_page
         hmrc_manual_section
         history
         manual
         manual_section
         news_article
         publication
         service_manual_guide
         statistical_data_set
         statistics_announcement]
    end
  end
end
