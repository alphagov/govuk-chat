class AnswerBlueprint < Blueprinter::Base
  identifier :id

  field :message
  field :created_at do |answer, _options|
    answer.created_at.iso8601
  end
  field :useful, if: ->(_field_name, answer, _options) { answer.feedback.present? } do |answer, _options|
    answer.feedback.useful
  end

  field :sources, if: ->(_field_name, answer, _options) { answer.sources.used.present? } do |answer, _options|
    answer.group_used_answer_sources_by_base_path.map do |source|
      source.transform_keys { |key| key == :href ? :url : key }
    end
  end
end
