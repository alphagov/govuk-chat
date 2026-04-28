RSpec.describe "Users interactions with chat are shown in admin area", :aws_credentials_stubbed, :chunked_content_index, :js do
  scenario do
    given_i_am_an_admin_with_the_web_chat_permission
    and_i_have_dismissed_the_cookie_banner

    when_i_visit_the_conversation_page
    and_i_enter_a_question
    and_the_answer_is_generated

    when_i_visit_the_admin_area
    and_i_browse_to_the_questions_section
    and_i_click_on_my_question
    then_i_see_the_answer
    and_i_dont_see_the_tagged_topics

    when_i_click_the_analysis_tab
    then_i_see_the_topics_have_been_tagged
    and_i_see_the_answer_relevancy_statistics
    and_i_dont_see_the_answer
  end

  def given_i_am_an_admin_with_the_web_chat_permission
    login_as(create(:signon_user, permissions: %w[admin-area web-chat]))
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_enter_a_question
    @question = "Should I open a business and what benefits could I claim if I do?"
    fill_in "Message", with: @question
    click_on "Send"
  end

  def and_the_answer_is_generated
    @answer = "Maybe. You could get some benefits."
    stubs_for_mock_answer(@question,
                          @answer,
                          sources_used: %w[link_1])

    execute_queued_sidekiq_jobs
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_questions_section
    click_link "Questions"
  end

  def and_i_click_on_my_question
    click_link @question
  end

  def then_i_see_the_answer
    expect(page).to have_content(@answer)
  end

  def and_i_dont_see_the_tagged_topics
    expect(page).not_to have_content("Business")
  end

  def when_i_click_the_analysis_tab
    click_link "Analysis"
  end

  def then_i_see_the_topics_have_been_tagged
    expect(page)
      .to have_content("Business")
      .and have_content("Benefits")
  end

  def and_i_dont_see_the_answer
    expect(page).not_to have_content(@answer)
  end

  def and_i_see_the_answer_relevancy_statistics
    expect(page).to have_content(/Mean score.*1.0/)
  end
end
