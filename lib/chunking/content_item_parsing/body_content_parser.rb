module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
    ANY_DOCUMENT_TYPE = ->(_) { true }.freeze

    SCHEMAS_TO_DOCUMENT_TYPE_CHECK = {
      "call_for_evidence" => ANY_DOCUMENT_TYPE,
      "case_study" => ANY_DOCUMENT_TYPE,
      "consultation" => ANY_DOCUMENT_TYPE,
      "corporate_information_page" => ANY_DOCUMENT_TYPE,
      "worldwide_corporate_information_page" => ANY_DOCUMENT_TYPE,
      "detailed_guide" => ANY_DOCUMENT_TYPE,
      "hmrc_manual_section" => ANY_DOCUMENT_TYPE,
      "history" => ANY_DOCUMENT_TYPE,
      "news_article" => ANY_DOCUMENT_TYPE,
      "publication" => ->(document_type) { %w[correspondence decision].exclude?(document_type) },
      "service_manual_guide" => ANY_DOCUMENT_TYPE,
      "speech" => ->(document_type) { %w[oral_statement written_statement].include?(document_type) },
      "statistical_data_set" => ANY_DOCUMENT_TYPE,
    }.freeze

    def call
      content = details_field!("body")

      build_chunks(content)
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
