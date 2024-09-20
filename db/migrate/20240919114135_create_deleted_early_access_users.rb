class CreateDeletedEarlyAccessUsers < ActiveRecord::Migration[7.2]
  def change
    create_enum :deleted_early_access_user_deletion_type, %w[unsubscribe admin]

    create_table :deleted_early_access_users, id: :uuid do |t|
      t.integer :login_count, default: 0
      t.enum :deletion_type, enum_type: "deleted_early_access_user_deletion_type", null: false
      t.enum :user_source, enum_type: "early_access_user_source", null: false
      t.datetime :user_created_at, null: false

      t.timestamps
    end
  end
end
