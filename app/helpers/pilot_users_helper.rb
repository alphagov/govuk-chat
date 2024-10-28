module PilotUsersHelper
  def user_research_question_text(question_label)
    Rails.configuration.pilot_user_research_questions.fetch(question_label.to_s).fetch("text")
  end

  def user_research_question_option_text(question_label, option_value)
    return "" unless option_value

    options = Rails.configuration.pilot_user_research_questions.fetch(question_label.to_s).options
    option = options.find { |o| o.value == option_value.to_s }
    raise "Option #{option_value} not found for question #{question_label}" unless option

    option.fetch("text")
  end

  def user_research_question_options_for_select(question_label, selected: nil)
    options = Rails.configuration.pilot_user_research_questions.fetch(question_label.to_s).options

    choices = options.map do |option|
      {
        value: option.fetch("value"),
        text: option.fetch("text"),
        selected: selected == option.value,
      }
    end

    [{ value: "", text: "", selected: selected == "" }] + choices
  end

  def user_research_question_items_for_radio(question_label, checked: nil)
    options = Rails.configuration.pilot_user_research_questions.fetch(question_label.to_s).options

    options.map do |option|
      {
        value: option.fetch("value"),
        text: option.fetch("text"),
        checked: checked == option.value,
      }
    end
  end
end
