module AutoEvaluationResultsExportable
  extend ActiveSupport::Concern

  included do
    scope :exportable, lambda { |start_date, end_date|
      joins(answer: { question: :conversation })
      .where(created_at: start_date...end_date)
    }
  end

  def serialize_for_export
    as_json(except: :llm_responses).merge(
      "llm_responses" => llm_responses.to_json,
    )
  end
end
