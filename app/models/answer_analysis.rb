class AnswerAnalysis < ApplicationRecord
  include LlmCallsRecordable

  belongs_to :answer

  scope :exportable, lambda { |start_date, end_date|
    where(created_at: start_date...end_date)
  }

  def serialize_for_export
    as_json(except: :llm_responses).merge("llm_responses" => llm_responses.to_json)
  end
end
