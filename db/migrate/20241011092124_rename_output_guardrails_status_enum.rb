class RenameOutputGuardrailsStatusEnum < ActiveRecord::Migration[7.2]
  def change
    rename_enum "output_guardrails_status", to: "guardrails_status"
  end
end
