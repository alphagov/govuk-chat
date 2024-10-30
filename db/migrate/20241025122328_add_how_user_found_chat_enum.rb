class AddHowUserFoundChatEnum < ActiveRecord::Migration[7.2]
  def up
    create_enum :ur_question_found_chat, %w[govuk_website govuk_blog social_media news personal_contact professional_contact official_government_announcement search_engine other]

    change_table :early_access_users, bulk: true do |t|
      t.enum :found_chat, enum_type: "ur_question_found_chat"
    end

    change_table :waiting_list_users, bulk: true do |t|
      t.enum :found_chat, enum_type: "ur_question_found_chat"
    end
  end

  def down
    change_table :early_access_users, bulk: true do |t|
      t.remove :found_chat
    end

    change_table :waiting_list_users, bulk: true do |t|
      t.remove :found_chat
    end

    drop_enum :ur_question_found_chat
  end
end
