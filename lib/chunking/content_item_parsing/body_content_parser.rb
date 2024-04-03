module Chunking::ContentItemParsing
  class BodyContentParser < BaseParser
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
