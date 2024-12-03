class AddNewStatusesToAnswers < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :status, "answered"
    add_enum_value :status, "banned"
    add_enum_value :status, "clarification"
    add_enum_value :status, "guardrails_answer"
    add_enum_value :status, "guardrails_forbidden_terms"
    add_enum_value :status, "guardrails_jailbreak"
    add_enum_value :status, "guardrails_question_routing"
    add_enum_value :status, "unanswerable_llm_cannot_answer"
    add_enum_value :status, "unanswerable_no_govuk_content"
    add_enum_value :status, "unanswerable_question_routing"
  end
end
