class AddJailbreakGuardrailStatusesToEnum < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :status, "abort_jailbreak_guardrails"
    add_enum_value :status, "error_jailbreak_guardrails"
  end
end
