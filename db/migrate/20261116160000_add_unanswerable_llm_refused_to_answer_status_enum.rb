class AddUnanswerableLlmRefusedToAnswerStatusEnum < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :answer_status, "unanswerable_llm_refused"
  end
end
