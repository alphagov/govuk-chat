class AnswerAnalysis::Topics < ApplicationRecord
  include LlmCallsRecordable

  self.table_name = "answer_analysis_topics"

  belongs_to :answer

  scope :exportable, lambda { |start_date, end_date|
    joins(answer: { question: :conversation })
    .where(created_at: start_date...end_date)
    .merge(Conversation.exclude_opted_out_end_user_ids)
  }

  def serialize_for_export
    as_json(except: :llm_responses).merge("llm_responses" => llm_responses.to_json)
  end
end
