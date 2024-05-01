module AnswersHelper
  def render_answer_message(message)
    render "govuk_publishing_components/components/govspeak" do
      sanitize(message)
    end
  end
end
