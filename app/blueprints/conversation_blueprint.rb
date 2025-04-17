class ConversationBlueprint < Blueprinter::Base
  identifier :id

  field :created_at do |conversation, _options|
    conversation.created_at.iso8601
  end

  association :answered_questions, blueprint: QuestionBlueprint, view: :answered do |_conversation, options|
    options[:answered_questions] || []
  end

  association :pending_question, blueprint: QuestionBlueprint, view: :pending,
                                 if: ->(_field_name, _conversation, options) { options[:pending_question].present? } do |_conversation, options|
    options[:pending_question]
  end
end
