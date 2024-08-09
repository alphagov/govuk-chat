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

    def self.allowed_schemas
      %w[step_by_step_nav]
    end

  private

    def parse_details_field
      structured_content = details_field!("step_by_step_nav")

      html_content = []
      html_content << "<p>#{structured_content.dig('introduction', 0, 'content')}</p>"

      nav_steps = structured_content["steps"]
      nav_steps.each do |nav_step|
        html_content << parse_nav_step(nav_step)
      end

      html_content.join("\n")
    end

    def parse_nav_step(nav_step)
      html_content = []
      html_content << tag.h2(nav_step["title"])

      nav_step["contents"].each do |content|
        case content["type"]
        when "paragraph"
          html_content << tag.p(content["text"])
        else
          raise "Unknown content type: #{content['type']}"
        end
      end

      html_content.join("\n")
    end
  end
end
