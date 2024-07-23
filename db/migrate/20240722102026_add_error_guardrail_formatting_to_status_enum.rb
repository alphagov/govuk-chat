class AddErrorGuardrailFormattingToStatusEnum < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "error_output_guardrails"
  end
end
