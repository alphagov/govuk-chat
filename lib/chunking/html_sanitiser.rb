module Chunking
  class HtmlSanitiser
    # block elements to extract content from
    ELEMENTS_TO_FLATTEN = %w[div section article main details nav header footer summary].freeze

    ALLOWED_ATTRIBUTES = {
      "h2" => %w[id],
      "h3" => %w[id],
      "h4" => %w[id],
      "h5" => %w[id],
      "h6" => %w[id],
      "a" => %w[href],
      "abbr" => %w[title],
    }.freeze

    def initialize(html)
      @doc = Nokogiri::HTML::DocumentFragment.parse(html)
    end

    def self.call(...) = new(...).call

    def call
      remove_footnotes
      strip_attributes
      remove_h1s
      flatten_html
      doc.to_html
    end

  private

    attr_reader :doc

    def remove_footnotes
      doc.css("div.footnotes").each(&:remove)
    end

    def strip_attributes
      doc.css("*").each do |node|
        node.attributes.each_key do |attribute_name|
          attribute_allowed = ALLOWED_ATTRIBUTES.fetch(node.name, []).include?(attribute_name)
          node.remove_attribute(attribute_name) unless attribute_allowed
        end
      end
    end

    def remove_h1s
      doc.css("h1").each(&:remove)
    end

    def flatten_html
      children = flatten_html_of_nodes(doc.children)
      doc.children = children.map(&:to_html).join
    end

    def flatten_html_of_nodes(child_nodes)
      child_nodes.inject([]) do |memo, node|
        if ELEMENTS_TO_FLATTEN.include?(node.name)
          memo += flatten_html_of_nodes(node.children)
        else
          memo << node
        end
        memo
      end
    end
  end
end
