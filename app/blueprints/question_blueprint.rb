class QuestionBlueprint < Blueprinter::Base
  identifier :id

  fields :message, :conversation_id

  field :created_at do |question, _options|
    question.created_at.iso8601
  end

  view :answered do
    association :answer, blueprint: AnswerBlueprint
  end

  view :pending do
    field :answer_url do |question|
      path = Rails.application.routes.url_helpers.answer_question_path(question.conversation_id, question.id)
      "#{Plek.website_root}#{path}"
    end
  end
end
