class AddAnswerGuardrailsEnumValues < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :status, "abort_answer_guardrails"
    add_enum_value :status, "error_answer_guardrails"
  end
end
