class AddQuestionsCountToEarlyAccessUser < ActiveRecord::Migration[7.1]
  def change
    add_column :early_access_users, :questions_count, :integer, default: 0
  end
end
