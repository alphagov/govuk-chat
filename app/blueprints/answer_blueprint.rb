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

  field :feedback, if: ->(_field_name, answer, _options) { answer.feedback.present? } do |answer, _options|
    {
      reaction: answer.feedback.reaction,
      created_at: answer.feedback.created_at.iso8601,
    }
  end

  field :feedback_url, if: ->(_field_name, answer, _options) { answer.feedback.blank? } do |answer, _options|
    Rails.application.routes.url_helpers.api_v1_answer_feedback_path(
      answer.question.conversation_id,
      answer.id,
    )
  end
end
