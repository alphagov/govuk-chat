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
      doc = Commonmarker.parse(markdown)
      rewrite_links(doc)

      # Strip any trailing newlines
      doc.to_commonmark.strip
    end

  private

    def rewrite_links(element)
      element.walk do |child|
        rewrite_link(child) if child.type == :link
      end
    end

    def rewrite_link(link_element)
      token = link_element.url

      if (url = link_for_token(token))
        link_element.url = url

        # If we have a link where the text is e.g. "link_1" then we should replace
        # it with "source". Showing "link_1" to the user makes it seem like something
        # is broken
        link_text = link_element.each.map(&:string_content).join
        if link_text =~ /#{TOKEN_PREFIX}\d+/
          # We need to delete all of the children, because a link with text of "link_1"
          # actually contains three child text nodes: "link", "_", and "1"
          link_element.each(&:delete)

          # Create a new text node with the text "source" and make it the link node's
          # only child
          text_node = Commonmarker::Node.new(:text)
          text_node.string_content = "source"
          link_element.append_child(text_node)
        end

      else
        # We don't have the link mapping stored, so we want to strip out the link
        # We can do this by getting all of the link's children and moving them
        # before the link, then deleting the link
        link_element.each do |child|
          link_element.insert_before(child)
        end
        link_element.delete
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
