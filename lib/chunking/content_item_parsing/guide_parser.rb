module Chunking
  module ContentItemParsing
    class GuideParser < BaseParser
      def call
        parts = details_field!("parts")

        chunked_parts = parts.map do |part|
          html = extract_html_from_multiple_content_types!(part["body"])

          {
            title: part["title"],
            url: "#{base_path}/#{part['slug']}",
            chunks: chunk_html(html),
          }
        end

        chunk_index = 0
        chunked_parts.flat_map do |chunked_part|
          chunked_part[:chunks].map do |html_chunk|
            chunk = ContentItemChunk.new(
              content_item:,
              html_content: html_chunk.html_content,
              heading_hierachy: [chunked_part[:title]] + html_chunk.headings,
              chunk_index:,
              chunk_url: append_fragment(chunked_part[:url], html_chunk.fragment),
            )

            chunk_index += 1
            chunk
          end
        end
      end
    end
  end
end
