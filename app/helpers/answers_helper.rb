module AnswersHelper
  def render_answer_message(message)
    message_to_html = Commonmarker.to_html(message, options: {
      extension: { autolink: false },
      render: { hardbreaks: false },
    })

    render "govuk_publishing_components/components/govspeak" do
      sanitize(message_to_html)
    end
  end
end
