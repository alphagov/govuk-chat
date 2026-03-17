module AnswersHelper
  def render_answer_message(message, skip_sanitize: false)
    message_to_html = Commonmarker.to_html(message, options: {
      extension: { autolink: false },
      render: { hardbreaks: false },
    })

    render "govuk_publishing_components/components/govspeak" do
      if skip_sanitize
        message_to_html.html_safe
      else
        sanitize(message_to_html)
      end
    end
  end
end
