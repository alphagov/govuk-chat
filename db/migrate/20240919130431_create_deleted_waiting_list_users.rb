class CreateDeletedWaitingListUsers < ActiveRecord::Migration[7.2]
  def change
    create_enum :deleted_waiting_list_user_deletion_type, %w[unsubscribe admin promotion]

    create_table :deleted_waiting_list_users, id: :uuid do |t|
      t.enum :deletion_type, enum_type: "deleted_waiting_list_user_deletion_type", null: false
      t.enum :user_source, enum_type: "waiting_list_users_source", null: false
      t.datetime :user_created_at, null: false

      t.timestamps
    end
  end
end
