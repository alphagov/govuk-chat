class RenameOutputGuardrailStatusToAnswerGuardrailsStatus < ActiveRecord::Migration[7.2]
  def change
    rename_column :answers, :output_guardrail_status, :answer_guardrails_status
  end
end
