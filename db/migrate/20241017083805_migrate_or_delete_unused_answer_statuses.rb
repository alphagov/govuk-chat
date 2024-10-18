class MigrateOrDeleteUnusedAnswerStatuses < ActiveRecord::Migration[7.2]
  class Answer < ApplicationRecord
    enum :status,
         {
           abort_output_guardrails: "abort_output_guardrails",
           abort_answer_guardrails: "abort_answer_guardrails",
           error_output_guardrails: "error_output_guardrails",
           error_answer_guardrails: "error_answer_guardrails",
           error_invalid_llm_response: "error_invalid_llm_response",
         }
  end

  def up
    Answer.where(status: :abort_output_guardrails).update_all(status: :abort_answer_guardrails)
    Answer.where(status: :error_output_guardrails).update_all(status: :error_answer_guardrails)
    Answer.where(status: :error_invalid_llm_response).destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
