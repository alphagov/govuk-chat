module Chunking
  module ContentItemParsing
    class BaseParser
      HtmlChunk = Data.define(:headings, :html_content) do
        # TODO: replace this with data from the HTML
        def fragment
          return unless headings.last

          headings.last.downcase.gsub(/[^0-9a-z ]/i, "").gsub("\s", "-")
        end
      end

      def self.call(...) = new(...).call

      def initialize(content_item)
        @content_item = content_item
      end

      def call
        raise "To be implemented in subclass"
      end

    private

      attr_reader :content_item

      # Most content types will just need to assemble HTML and call this method
      # For more complex content types, such as those with parts, they may need
      # to create the chunk objects directly.
      def build_chunks(html)
        html_chunks = chunk_html(html)
        html_chunks.map.with_index do |html_chunk, index|
          ContentItemChunk.new(
            content_item:,
            html_content: html_chunk.html_content,
            heading_hierarchy: html_chunk.headings,
            chunk_index: index,
            chunk_url: append_fragment(base_path, html_chunk.fragment),
          )
        end
      end

      def chunk_html(html)
        # TODO: Have HtmlHierachicalChunker class return an array of objects so we don't need
        # to process the return value
        chunks = Chunking::HtmlHierarchicalChunker.call(title: "", html:)

        chunks.map do |chunk|
          headings = chunk.select { |k, _| k.match?(/\Ah[2-6]\Z/) }.sort.map(&:last)
          HtmlChunk.new(headings, chunk["html_content"])
        end
      end

      def base_path
        content_item["base_path"]
      end

      def details_field!(*field_path)
        result = details_field(*field_path)

        unless result
          raise "nil value in details hash for #{field_path.join(', ')} in schema: #{content_item['schema_name']}"
        end

        result
      end

      def details_field(*field_path)
        content_item.dig("details", *field_path)
      end

      def extract_html_from_multiple_content_types!(...)
        html = extract_html_from_multiple_content_types(...)

        unless html
          raise "content type text/html not found in schema: #{content_item['schema_name']}"
        end

        html
      end

      def extract_html_from_multiple_content_types(content)
        html = content.find { |k, _| k["content_type"] == "text/html" }
        return unless html

        html["content"]
      end

      def append_fragment(path, fragment)
        return path unless fragment

        "#{path}##{fragment}"
      end
    end
  end
end
