class AddSourceToEarlyAccessUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :early_access_users, :source, :enum, enum_type: "early_access_user_source", null: false # rubocop:disable Rails/NotNullColumn
  end
end
