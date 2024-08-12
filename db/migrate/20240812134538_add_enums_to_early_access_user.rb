class AddEnumsToEarlyAccessUser < ActiveRecord::Migration[7.1]
  def up
    create_enum :ur_question_user_description, %w[business_owner_or_self_employed starting_business_or_becoming_self_employed business_advisor business_administrator none]
    create_enum :ur_question_reason_for_visit, %w[find_specific_answer complete_task understand_process research_topic other]

    change_table :early_access_users, bulk: true do |t|
      t.enum :user_description, enum_type: "ur_question_user_description"
      t.enum :reason_for_visit, enum_type: "ur_question_reason_for_visit"
    end
  end

  def down
    change_table :early_access_users, bulk: true do |t|
      t.remove :user_description
      t.remove :reason_for_visit
    end

    drop_enum :ur_question_user_description
    drop_enum :ur_question_reason_for_visit
  end
end
