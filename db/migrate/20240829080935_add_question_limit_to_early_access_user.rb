class AddQuestionLimitToEarlyAccessUser < ActiveRecord::Migration[7.2]
  def change
    add_column :early_access_users, :question_limit, :integer, null: true
  end
end
