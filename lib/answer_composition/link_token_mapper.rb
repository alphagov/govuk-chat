module AnswerComposition
  class LinkTokenMapper
    attr_reader :mapping

    def initialize
      @mapping = {}
    end

    def map_links_to_tokens(html_content)
      doc = Nokogiri::HTML::DocumentFragment.parse(html_content)

      doc.css("a").each do |link|
        href = link["href"]

        if mapping.key?(href)
          link["href"] = mapping[href]
        else
          token = "link_#{mapping.count + 1}"
          mapping[href] = token
          link["href"] = token
        end
      end

      doc.to_html
    end
  end
end
