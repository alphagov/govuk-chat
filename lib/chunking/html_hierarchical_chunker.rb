module Chunking
  # TODO: Iterate this class:
  # - would be good to preserve header anchor ids so they can be used in urls
  # - it's hard to work with the headers being hash keys - it'd be easier to have an array of headers - I don't think
  #   we care which level they are just the hierarchy
  # - it would be helpful if this class returned an array of data objects rather than an array of hashes
  class HtmlHierarchicalChunker
    def initialize(html)
      @doc = Nokogiri::HTML::DocumentFragment.parse(html)
      @headers = {}
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
      headers_to_keep = headers.keys.select { |h| h < node.name }
      @headers = headers.slice(*headers_to_keep).merge({ node.name => node.text })
    end

    def save_chunk
      return if current_chunk["html_content"].empty?

      chunks.append(current_chunk)
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

    def current_chunk
      headers.merge({
        "html_content" => content.join("\n"),
      })
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
