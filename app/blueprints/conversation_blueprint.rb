class ConversationBlueprint < Blueprinter::Base
  identifier :id

  field :created_at, datetime_format: ->(datetime) { datetime.iso8601 }

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

  field(
    :earlier_questions_url,
    if: ->(_field_name, _conversation, options) { options[:earlier_questions_url].present? },
  ) do |_conversation, options|
    options[:earlier_questions_url]
  end
end
