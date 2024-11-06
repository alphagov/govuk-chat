class MigrateErrorQuestionRoutingAnswerStatus < ActiveRecord::Migration[7.2]
  class Answer < ApplicationRecord
    enum :status,
         {
           error_question_routing: "error_question_routing",
           error_non_specific: "error_non_specific",
         }
  end

  def up
    Answer.where(status: :error_question_routing).update_all(status: :error_non_specific)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
