class AddAbortLlmCannotAnswerToAnswerStatusEnum < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "abort_llm_cannot_answer"
  end
end
