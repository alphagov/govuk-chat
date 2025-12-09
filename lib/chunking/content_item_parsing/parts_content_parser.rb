module Chunking
  module ContentItemParsing
    class PartsContentParser < BaseParser
      def call
        chunk_index = 0
        chunked_parts.flat_map do |chunked_part|
          chunked_part[:chunks].map do |html_chunk|
            chunk = ContentItemChunk.new(
              content_item:,
              html_content: html_chunk.html_content,
              heading_hierarchy: [chunked_part[:title]] + html_chunk.headers.map(&:text_content),
              chunk_index:,
              exact_path: append_fragment(chunked_part[:exact_path], html_chunk.fragment),
            )

            chunk_index += 1
            chunk
          end
        end
      end

    protected

      def parts
        details_field!("parts")
      end

      def chunked_parts
        parts.map.with_index do |part, index|
          html = extract_html_from_multiple_content_types!(part["body"])

          # GOV.UK doesn't include slug in the URL for the first part, so we'll match that logic
          exact_path = index.zero? ? base_path : "#{base_path}/#{part['slug']}"

          {
            title: part["title"],
            exact_path:,
            chunks: Chunking::HtmlHierarchicalChunker.call(html),
          }
        end
      end
    end
  end
end
