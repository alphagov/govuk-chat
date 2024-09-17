class RemoveOldAnswerStatusValues < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
    ALTER TYPE status RENAME TO status_old;

    CREATE TYPE status AS ENUM(
                            'success',
                            'error_non_specific',
                            'error_answer_service_error',
                            'error_context_length_exceeded',
                            'abort_no_govuk_content',
                            'error_invalid_llm_response',
                            'abort_output_guardrails',
                            'error_output_guardrails',
                            'abort_llm_cannot_answer',
                            'abort_question_routing',
                            'error_question_routing',
                            'error_timeout');

    ALTER TABLE answers ALTER COLUMN status TYPE status USING status::text::status;

    DROP TYPE status_old;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
