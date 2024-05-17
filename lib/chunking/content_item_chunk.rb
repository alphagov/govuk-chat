module Chunking
  class ContentItemChunk
    attr_reader :content_item, :html_content, :heading_hierarchy, :chunk_index, :chunk_url

    def initialize(content_item:, html_content:, heading_hierarchy:, chunk_index:, chunk_url: nil)
      @content_item = content_item
      @html_content = html_content
      @heading_hierarchy = heading_hierarchy
      @chunk_index = chunk_index
      @chunk_url = chunk_url
    end

    def plain_content
      @plain_content ||= begin
        stripped_html = Nokogiri::HTML::DocumentFragment.parse(html_content)
        values = [title] + heading_hierarchy + [stripped_html, description]
        values.compact.join("\n")
      end
    end

    def id
      "#{content_id}_#{locale}_#{chunk_index}"
    end

    def content_id
      content_item["content_id"]
    end

    def locale
      content_item["locale"]
    end

    def title
      content_item["title"]
    end

    def description
      content_item["description"]
    end

    def base_path
      content_item["base_path"]
    end

    def document_type
      content_item["document_type"]
    end

    def url
      chunk_url || base_path
    end

    def digest
      @digest ||= begin
        values = [html_content,
                  heading_hierarchy,
                  chunk_index,
                  url,
                  content_id,
                  locale,
                  title,
                  description,
                  base_path,
                  document_type,
                  plain_content]

        Digest::SHA2.new(256).hexdigest(JSON.dump(values))
      end
    end

    def to_opensearch_hash
      {
        content_id:,
        locale:,
        base_path:,
        document_type:,
        title:,
        description:,
        url:,
        chunk_index:,
        heading_hierarchy:,
        html_content:,
        plain_content:,
        digest:,
      }
    end

    def inspect
      values = {
        html_content:,
        heading_hierarchy:,
        chunk_index:,
        url:,
        content_id:,
        locale:,
        title:,
        description:,
        base_path:,
        document_type:,
      }
      string_parts = values.map { |k, v| "#{k}: #{v.inspect}" }

      %{#{self.class.name}(\n#{string_parts.join("\n")}\n)}
    end
  end
end
