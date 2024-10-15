class RenameOutputGuardrailFailures < ActiveRecord::Migration[7.2]
  def change
    rename_column :answers, :output_guardrail_failures, :answer_guardrails_failures
  end
end
