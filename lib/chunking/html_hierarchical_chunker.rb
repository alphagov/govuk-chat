module Chunking
  # TODO: Iterate this class:
  # - would be good to preserve header anchor ids so they can be used in urls
  class HtmlHierarchicalChunker
    HtmlChunk = Data.define(:headers, :html_content)
    HtmlChunk::Header = Data.define(:element, :text_content)

    def initialize(html)
      @doc = Nokogiri::HTML::DocumentFragment.parse(html)
      @headers = []
      @chunks = []
      @content = []
    end

    def self.call(...) = new(...).call

    def call
      remove_footnotes
      clean_attributes
      remove_h1s
      split_nodes(doc.children)
      chunks
    end

  private

    attr_reader :doc, :headers, :content, :chunks

    def split_nodes(child_nodes)
      child_nodes.each do |node|
        if node.name == "div"
          save_chunk
          split_nodes(node.children)
          next
        end
        if header?(node)
          save_chunk
          new_header(node)
        else
          add_content(node.to_html.chomp)
        end
      end
      save_chunk
    end

    def header?(node)
      node.element? && node.name.match?(/^h[2-6]$/)
    end

    def new_header(node)
      header = HtmlChunk::Header.new(element: node.name, text_content: node.text)
      headers_to_keep = headers.select { |h| h.element < header.element }
      @headers = headers_to_keep.append(header)
    end

    def save_chunk
      return if content.empty?

      chunk = HtmlChunk.new(headers:, html_content: content.join("\n"))
      chunks.append(chunk)
      @content = []
    end

    def new_chunk(header_node)
      save_chunk
      headers_to_keep = headers.keys.select { |h| h < header_node.name }
      @headers = headers.slice(*headers_to_keep)
      add_header(header_node.name, header_node.text)
    end

    def add_content(html)
      return if html.strip.empty?

      content.append(html.strip)
    end

    def clean_attributes
      doc.css("*").each do |node|
        AttributeStripper.call(node)
      end
    end

    def remove_footnotes
      doc.css("div.footnotes").each(&:remove)
    end

    def remove_h1s
      doc.css("h1").each(&:remove)
    end
  end
end
