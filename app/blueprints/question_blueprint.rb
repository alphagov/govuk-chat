class QuestionBlueprint < Blueprinter::Base
  identifier :id

  fields :message, :conversation_id

  field :created_at, datetime_format: ->(datetime) { datetime.iso8601 }

  view :answered do
    association :answer, blueprint: AnswerBlueprint
  end

  view :pending do
    field :answer_url do |_question, options|
      options[:answer_url]
    end
  end
end
