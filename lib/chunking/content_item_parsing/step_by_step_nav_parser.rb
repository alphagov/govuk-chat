module Chunking::ContentItemParsing
  class StepByStepNavParser < BaseParser
    include ActionView::Helpers::TagHelper

    def call
      [
        Chunking::ContentItemChunk.new(
          content_item:,
          html_content: parse_details_field,
          heading_hierarchy: [],
          chunk_index: 0,
          exact_path: base_path,
        ),
      ]
    end

  private

    def parse_details_field
      structured_content = details_field!("step_by_step_nav")
      html_content = []

      introduction = structured_content.dig("introduction", 1, "content")
      sanitsed_introduction = Chunking::HtmlSanitiser.new(introduction).call.strip
      html_content << sanitsed_introduction

      nav_steps = structured_content["steps"]
      nav_steps.each do |nav_step|
        html_content << parse_nav_step(nav_step)
      end

      html_content.join("\n")
    end

    def parse_nav_step(nav_step)
      html_content = []
      html_content << "\n#{tag.p('and')}\n" if nav_step["logic"] == "and"
      html_content << "\n#{tag.p('or')}\n" if nav_step["logic"] == "or"
      html_content << tag.h2(nav_step["title"])

      nav_step["contents"].each do |content|
        case content["type"]
        when "paragraph"
          html_content << tag.p(content["text"])
        when "list"
          html_content << list_html(content)
        else
          raise "Unknown content type: #{content['type']}"
        end
      end

      html_content.join("\n")
    end

    def list_html(content)
      links = content["contents"]

      list_items = links.map do |link|
        item = if link["href"]
                 tag.a(link["text"], href: link["href"])
               else
                 link["text"]
               end

        item = safe_join([item, tag.span(link["context"])], " ") if link["context"]

        tag.li(item)
      end

      list_type = content["style"] == "choice" ? "ul" : "ol"
      content_tag(list_type, safe_join(list_items, "\n"))
    end
  end
end
