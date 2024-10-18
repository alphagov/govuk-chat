class MoveAbortTimeoutToErrorTimeout < ActiveRecord::Migration[7.2]
  class Answer < ApplicationRecord
    enum :status,
         {
           abort_timeout: "abort_timeout",
           error_timeout: "error_timeout",
         }
  end

  def up
    Answer.where(status: :abort_timeout).update_all(status: :error_timeout)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
