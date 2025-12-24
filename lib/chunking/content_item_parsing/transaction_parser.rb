module Chunking::ContentItemParsing
  class TransactionParser < BaseParser
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
  end
end
