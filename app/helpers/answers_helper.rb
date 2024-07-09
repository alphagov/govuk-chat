module AnswersHelper
  def render_answer_message(message)
    message_to_html = Kramdown::Document.new(message).to_html
    render "govuk_publishing_components/components/govspeak" do
      sanitize(message_to_html)
    end
  end
end
