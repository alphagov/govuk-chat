module Chunking
  module ContentItemParsing
    class GuideParser < BaseParser
      ALLOWED_SCHEMAS = %w[guide].freeze

      def call
        parts = details_field!("parts")

        chunked_parts = parts.map do |part|
          html = extract_html_from_multiple_content_types!(part["body"])

          {
            title: part["title"],
            url: "#{base_path}/#{part['slug']}",
            chunks: Chunking::HtmlHierarchicalChunker.call(html),
          }
        end

        chunk_index = 0
        chunked_parts.flat_map do |chunked_part|
          chunked_part[:chunks].map do |html_chunk|
            chunk = ContentItemChunk.new(
              content_item:,
              html_content: html_chunk.html_content,
              heading_hierarchy: [chunked_part[:title]] + html_chunk.headers.map(&:text_content),
              chunk_index:,
              chunk_url: append_fragment(chunked_part[:url], html_chunk.fragment),
            )

            chunk_index += 1
            chunk
          end
        end
      end

      def self.supported_schema_and_document_type?(schema_name, _document_type)
        ALLOWED_SCHEMAS.include?(schema_name)
      end
    end
  end
end
