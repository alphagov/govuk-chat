module Chunking::ContentItemParsing
  class BodyContentArrayParser < BaseParser
    SCHEMAS_TO_DOCUMENT_TYPE_CHECK = {
      "answer" => ANY_DOCUMENT_TYPE,
      "specialist_document" => lambda { |document_type|
        %w[ai_assurance_portfolio_technique
           business_finance_support_scheme
           esi_fund].include?(document_type)
      },
      "help_page" => ANY_DOCUMENT_TYPE,
      "manual" => ANY_DOCUMENT_TYPE,
      "manual_section" => ANY_DOCUMENT_TYPE,
    }.freeze

    def call
      content = details_field!("body")

      html = extract_html_from_multiple_content_types!(content)

      build_chunks(html)
    end

    def self.supported_schema_and_document_type?(schema_name, document_type)
      document_type_check = SCHEMAS_TO_DOCUMENT_TYPE_CHECK[schema_name]
      return false unless document_type_check

      document_type_check.call(document_type)
    end

    def self.allowed_schemas
      SCHEMAS_TO_DOCUMENT_TYPE_CHECK.keys
    end
  end
end
