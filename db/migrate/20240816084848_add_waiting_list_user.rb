class AddWaitingListUser < ActiveRecord::Migration[7.2]
  def change
    create_enum :waiting_list_users_source, %w[admin_added insufficient_instant_places]

    create_table :waiting_list_users, id: :uuid do |t|
      t.citext :email, null: false, index: { unique: true }
      t.enum :user_description, enum_type: "ur_question_user_description", null: true
      t.enum :reason_for_visit, enum_type: "ur_question_reason_for_visit", null: true
      t.enum :source, enum_type: "waiting_list_users_source", null: false

      t.timestamps
    end
  end
end
