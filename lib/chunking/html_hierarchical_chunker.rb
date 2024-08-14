module Chunking
  class HtmlHierarchicalChunker
    def initialize(html)
      @html = html
      @headers = []
      @chunks = []
      @content = []
    end

    def self.call(...) = new(...).call

    def call
      sanitised_html = HtmlSanitiser.call(html)
      document = Nokogiri::HTML::DocumentFragment.parse(sanitised_html)
      build_chunks(document.children)
    end

  private

    attr_reader :html, :headers, :content, :chunks

    def build_chunks(child_nodes)
      child_nodes.each do |node|
        if header?(node)
          save_chunk
          new_header(node)
        else
          add_content(node.to_html.chomp)
        end
      end
      save_chunk
      chunks
    end

    def header?(node)
      node.element? && node.name.match?(/^h[2-6]$/)
    end

    def new_header(node)
      header = HtmlChunk::Header.new(element: node.name, text_content: node.text, fragment: node["id"])
      headers_to_keep = headers.select { |h| h.element < header.element }
      @headers = headers_to_keep.append(header)
    end

    def save_chunk
      return if content.empty?

      chunk = HtmlChunk.new(headers:, html_content: content.join("\n"))
      chunks.append(chunk)
      @content = []
    end

    def add_content(html)
      return if html.strip.empty?

      content.append(html.strip)
    end
  end
end
