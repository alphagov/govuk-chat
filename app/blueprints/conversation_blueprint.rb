class ConversationBlueprint < Blueprinter::Base
  identifier :id

  field :created_at, datetime_format: ->(datetime) { datetime.iso8601 }
  field(
    :answered_questions_count,
    if: ->(_field_name, _conversation, options) { options[:answered_questions_count].present? },
  ) do |_conversation, options|
    options[:answered_questions_count]
  end

  association(
    :answered_questions,
    blueprint: QuestionBlueprint,
    view: :answered,
  ) do |_conversation, options|
    options[:answered_questions] || []
  end

  association(
    :pending_question,
    blueprint: QuestionBlueprint,
    view: :pending,
    if: ->(_field_name, _conversation, options) { options[:pending_question].present? },
  ) do |_conversation, options|
    options[:pending_question]
  end
end
