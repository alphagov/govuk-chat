module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    ALLOWED_SCHEMAS = %w[answer
                         call_for_evidence
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
                         statistics_announcement].freeze

    def call
      content = details_field!("body")

      html = if content.is_a?(Array)
               extract_html_from_multiple_content_types!(content)
             else
               content
             end

      build_chunks(html)
    end
  end
end
