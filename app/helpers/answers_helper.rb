module AnswersHelper
  def render_answer_message(message)
    message_to_html = Kramdown::Document.new(message).to_html
    render "govuk_publishing_components/components/govspeak" do
      sanitize(message_to_html)
    end
  end

  def group_used_answer_sources_by_base_path(answer)
    sources_by_base_path = answer.sources.used.group_by(&:base_path)

    sources_by_base_path.map do |base_path, group|
      result = group.first
      path = group.count == 1 ? result.exact_path : base_path

      title = result.title
      title += ": #{result.heading}" if group.count == 1 && result.heading.present?

      {
        href: "#{Plek.website_root}#{path}",
        title:,
      }
    end
  end
end
