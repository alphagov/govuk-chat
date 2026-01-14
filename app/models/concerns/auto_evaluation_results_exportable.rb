module AutoEvaluationResultsExportable
  extend ActiveSupport::Concern

  def serialize_for_export
    as_json(except: :llm_responses).merge(
      "llm_responses" => llm_responses.to_json,
    )
  end
end
