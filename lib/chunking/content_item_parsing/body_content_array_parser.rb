module Chunking::ContentItemParsing
  class BodyContentArrayParser < BaseParser
    ALLOWED_SPECIALIST_DOCUMENT_TYPES = %w[business_finance_support_scheme
                                           export_health_certificate
                                           international_development_fund
                                           licence_transaction].freeze

    SCHEMAS_TO_DOCUMENT_TYPE_CHECK = {
      "answer" => ANY_DOCUMENT_TYPE,
      "specialist_document" => lambda { |document_type|
        ALLOWED_SPECIALIST_DOCUMENT_TYPES.include?(document_type)
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

    def self.non_indexable_content_item_reason(content_item)
      schema_name = content_item["schema_name"]
      document_type_check = SCHEMAS_TO_DOCUMENT_TYPE_CHECK[schema_name]

      document_type = content_item["document_type"]
      return if document_type_check&.call(document_type)

      "document type: #{document_type} not supported for schema: #{schema_name}"
    end

    def self.allowed_schemas
      SCHEMAS_TO_DOCUMENT_TYPE_CHECK.keys
    end
  end
end
