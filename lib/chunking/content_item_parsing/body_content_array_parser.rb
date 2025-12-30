module Chunking::ContentItemParsing
  class BodyContentArrayParser < BaseParser
    def call
      content = details_field!("body")

      html = extract_html_from_multiple_content_types!(content)

      build_chunks(html)
    end
  end
end
