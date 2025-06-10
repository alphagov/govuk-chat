class RemovePilotUserTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :early_access_users
    drop_table :waiting_list_users
    drop_table :deleted_early_access_users
    drop_table :deleted_waiting_list_users
  end

  def down
    create_table :early_access_users, id: :uuid do |t|
      t.citext :email, null: false, index: { unique: true }
      t.datetime :last_login_at, null: true

      t.timestamps
    end

    create_table :waiting_list_users, id: :uuid do |t|
      t.citext :email, null: false, index: { unique: true }
      t.enum :user_description, enum_type: "ur_question_user_description", null: true
      t.enum :reason_for_visit, enum_type: "ur_question_reason_for_visit", null: true
      t.enum :source, enum_type: "waiting_list_users_source", null: false

      t.timestamps
    end

    create_table :deleted_early_access_users, id: :uuid do |t|
      t.integer :login_count, default: 0
      t.enum :deletion_type, enum_type: "deleted_early_access_user_deletion_type", null: false
      t.enum :user_source, enum_type: "early_access_user_source", null: false
      t.datetime :user_created_at, null: false

      t.timestamps
    end

    create_table :deleted_waiting_list_users, id: :uuid do |t|
      t.enum :deletion_type, enum_type: "deleted_waiting_list_user_deletion_type", null: false
      t.enum :user_source, enum_type: "waiting_list_users_source", null: false
      t.datetime :user_created_at, null: false

      t.timestamps
    end
  end
end
