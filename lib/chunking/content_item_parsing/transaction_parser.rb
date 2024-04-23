module Chunking::ContentItemParsing
  class TransactionParser < BaseParser
    ALLOWED_SCHEMAS = %w[transaction].freeze

    def call
      multiple_content_type_fields = %w[introductory_paragraph
                                        more_information
                                        other_ways_to_apply
                                        what_you_need_to_know]

      html = multiple_content_type_fields.map { |field| details_field(field) }
                                         .compact
                                         .map { |data| extract_html_from_multiple_content_types!(data) }
                                         .join("\n")

      build_chunks(html)
    end

    def self.supported_schema_and_document_type?(schema_name, _document_type)
      ALLOWED_SCHEMAS.include?(schema_name)
    end
  end
end
