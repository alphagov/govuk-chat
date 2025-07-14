class RemoveUnusedAnswerStatusEnumValues < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
    ALTER TYPE answer_status RENAME TO answer_status_old;

    CREATE TYPE answer_status AS ENUM(
                            'answered',
                            'clarification',
                            'error_answer_guardrails',
                            'error_answer_service_error',
                            'error_jailbreak_guardrails',
                            'error_non_specific',
                            'error_question_routing_guardrails',
                            'error_timeout',
                            'guardrails_answer',
                            'guardrails_forbidden_terms',
                            'guardrails_jailbreak',
                            'guardrails_question_routing',
                            'unanswerable_llm_cannot_answer',
                            'unanswerable_no_govuk_content',
                            'unanswerable_question_routing');

    ALTER TABLE answers ALTER COLUMN status TYPE answer_status USING status::text::answer_status;

    DROP TYPE answer_status_old;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
