class AddAbortErrorQuestionRoutingGuardrails < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :status, "abort_question_routing_guardrails"
    add_enum_value :status, "error_question_routing_guardrails"
  end
end
