class MigrateOrDeleteUnusedAnswerStatuses < ActiveRecord::Migration[7.2]
  def up
    if Answer.statuses.keys.include?("abort_output_guardrails")
      Answer.where(status: :abort_output_guardrails).update_all(status: :abort_answer_guardrails)
    end

    if Answer.statuses.keys.include?("error_output_guardrails")
      Answer.where(status: :error_output_guardrails).update_all(status: :error_answer_guardrails)
    end

    if Answer.statuses.keys.include?("error_invalid_llm_response")
      Answer.where(status: :error_invalid_llm_response).destroy_all
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
