class AnswerBlueprint < Blueprinter::Base
  identifier :id

  field :message
  field :created_at do |answer, _options|
    answer.created_at.iso8601
  end
  field :useful, if: ->(_field_name, answer, _options) { answer.feedback.present? } do |answer, _options|
    answer.feedback.useful
  end
  association :sources, blueprint: AnswerSourceBlueprint,
                        if: ->(_field_name, answer, _options) { answer.sources.present? }
end
