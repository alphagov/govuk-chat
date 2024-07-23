class AddAbortOutputGuardrailsEnumToStatus < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "abort_output_guardrails"
  end
end
