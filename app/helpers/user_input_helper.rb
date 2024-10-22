module UserInputHelper
  def escaped_simple_format(string, html_options = {})
    simple_format(html_escape(string), html_options)
  end

  def remaining_questions_copy(user)
    return nil if user.nil? || user.unlimited_question_allowance?
    return nil if user.questions_remaining > Rails.configuration.conversations.question_warning_threshold

    "#{pluralize(user.questions_remaining, 'message')} left"
  end
end
