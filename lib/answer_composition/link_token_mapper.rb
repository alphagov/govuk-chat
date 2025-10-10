module AnswerComposition
  class LinkTokenMapper
    TOKEN_PREFIX = "link_".freeze
    attr_reader :mapping

    def initialize
      @mapping = {}
    end

    def map_links_to_tokens(html_content, exact_path)
      doc = Nokogiri::HTML::DocumentFragment.parse(html_content)

      doc.css("a").each do |link|
        next unless link["href"]

        link["href"] = map_link_to_token(link["href"], exact_path)
      end

      doc.to_html
    end

    def map_link_to_token(link, base_path = nil)
      link = begin
        if base_path.present?
          URI.join(ensure_absolute_url(base_path), link).to_s
        else
          ensure_absolute_url(link)
        end
      rescue URI::InvalidURIError, URI::InvalidComponentError
        link
      end

      return mapping[link] if mapping[link]

      token = "#{TOKEN_PREFIX}#{mapping.count + 1}"
      mapping[link] = token
      token
    end

    def link_for_token(token)
      mapping.key(token)
    end

    def replace_tokens_with_links(markdown)
      doc = Kramdown::Document.new(markdown)
      rewrite_links(doc.root)

      # `to_kramdown` adds 2 trailing newlines, so let's strip those
      doc.to_kramdown.strip
    end

  private

    def rewrite_links(element)
      if element.type == :a
        rewrite_link(element)
      else
        element.children.map!(&method(:rewrite_links))
        element
      end
    end

    def rewrite_link(link_element)
      token = link_element.attr["href"]

      if (url = link_for_token(token))
        link_element.tap do |el|
          el.attr["href"] = url

          # If we have a link where the text is e.g. "link_1" then we should replace
          # it with "source". Showing "link_1" to the user makes it seem like something
          # is broken
          el.children.each do |child|
            child.value = "source" if child.value =~ /#{TOKEN_PREFIX}\d+/
          end
        end
      else
        # We don't have the link mapping stored, so we want to strip out the link
        # We can do this by just returning the first child of the link node, as that's
        # everything that comes between the <a> tags, which might just be one text
        # node or it might be a whole sub-tree of nodes
        link_element.children.first
      end
    end

    def ensure_absolute_url(url)
      # We frequently host GOV.UK chat in environments off www.gov.uk
      # and need links not to be relative so that they will work.
      relative_uri = URI(url)

      return url if relative_uri.absolute?

      absolute_uri = URI(Plek.website_root)
      absolute_uri.path = relative_uri.path
      absolute_uri.query = relative_uri.query
      absolute_uri.fragment = relative_uri.fragment
      absolute_uri.to_s
    end
  end
end
