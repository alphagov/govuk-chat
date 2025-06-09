class RemoveUserResearchEnums < ActiveRecord::Migration[8.0]
  def up
    drop_enum :ur_question_user_description
    drop_enum :ur_question_reason_for_visit
    drop_enum :ur_question_found_chat
  end

  def down
    create_enum :ur_question_user_description, %w[business_owner_or_self_employed starting_business_or_becoming_self_employed business_advisor business_administrator none]
    create_enum :ur_question_reason_for_visit, %w[find_specific_answer complete_task understand_process research_topic other]
    create_enum :ur_question_found_chat, %w[govuk_website govuk_blog social_media news personal_contact professional_contact official_government_announcement search_engine other]
  end
end
