class QuestionBlueprint < Blueprinter::Base
  identifier :id

  fields :message, :conversation_id

  field :created_at, datetime_format: ->(datetime) { datetime.iso8601 }

  view :answered do
    association :answer, blueprint: AnswerBlueprint
  end

  view :pending do
    field :answer_url do |question|
      path = Rails.application.routes.url_helpers.api_v0_answer_question_path(
        question.conversation_id,
        question.id,
      )
      "#{Plek.website_root}#{path}"
    end
  end
end
