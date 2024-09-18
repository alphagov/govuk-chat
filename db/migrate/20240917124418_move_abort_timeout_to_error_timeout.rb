class MoveAbortTimeoutToErrorTimeout < ActiveRecord::Migration[7.2]
  def up
    Answer.where(status: :abort_timeout).update_all(status: :error_timeout)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
