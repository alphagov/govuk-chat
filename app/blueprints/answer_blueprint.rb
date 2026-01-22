class AnswerBlueprint < Blueprinter::Base
  identifier :id

  field :message
  field :created_at do |answer, _options|
    answer.created_at.iso8601
  end

  field :sources, if: ->(_field_name, answer, _options) { answer.sources.used.present? } do |answer, _options|
    answer.group_used_answer_sources_by_path.map do |source|
      { url: source[:href], title: source[:title] }
    end
  end
end
