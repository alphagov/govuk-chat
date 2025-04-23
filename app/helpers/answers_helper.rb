module AnswersHelper
  def render_answer_message(message, skip_sanitize: false)
    message_to_html = Kramdown::Document.new(message).to_html
    render "govuk_publishing_components/components/govspeak" do
      if skip_sanitize
        message_to_html.html_safe
      else
        sanitize(message_to_html)
      end
    end
  end

  def show_question_limit_system_message?(user)
    return false if user.nil?
    return false if user.unlimited_question_allowance?
    return true if user.questions_remaining.zero?

    user.questions_remaining == Rails.configuration.conversations.question_warning_threshold
  end
end
