module Chunking
  module ContentItemParsing
    class TravelGuideParser < PartsContentParser
      LLM_INSTRUCTIONS_PREFIX = "THERE IS CRITICAL INFORMATION FOR THIS CONTENT! USE THIS INFORMATION IN YOUR ANSWER WHEN IT IS RELEVANT TO THE QUESTION:".freeze

      include ActionView::Helpers

      def initialize(content_item)
        super(content_item.dup)

        if alert_status.any?
          # If we have any alert statuses in this content item, we want to append
          # a summary of them to the description field. This allows us to access
          # the alerts when searching the index, and pass them to the LLM when
          # generating answers.
          @content_item["description"] = [
            @content_item["description"],
            *alert_status_warnings,
          ].compact.join(" ")
        end
      end

    private

      def chunked_parts
        super.unshift(alert_part).compact
      end

      def alert_part
        return nil if alert_status.empty?

        {
          title: "Alert status",
          exact_path: base_path,
          chunks: Chunking::HtmlHierarchicalChunker.call(alert_status_html),
        }
      end

      def country_name
        details_field!("country").fetch("name")
      end

      def alert_status
        details_field!("alert_status")
      end

      def alert_status_warnings
        @alert_status_warnings ||= alert_status.filter_map do |status|
          warning = Rails.configuration.travel_alert_statuses.fetch(status) do
            GovukError.notify(
              "Unknown travel alert status: #{status}",
              extra: { content_item_id: content_item["content_id"], base_path: content_item["base_path"] },
            )
          end
          next if warning.nil?

          sprintf(warning, country: country_name)
        end
      end

      def alert_status_html
        items = alert_status_warnings.map do |warning|
          content_tag(:li, warning)
        end

        content_tag(:ul, safe_join(items))
      end

      def llm_instructions
        return nil if alert_status.empty?

        "#{LLM_INSTRUCTIONS_PREFIX} #{alert_status_warnings.join(' ')}"
      end
    end
  end
end
