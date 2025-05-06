RSpec.describe "Admin user filters questions" do
  scenario do
    given_i_am_an_admin
    and_there_are_questions

    when_i_visit_the_admin_area
    and_i_browse_to_the_questions_section
    and_i_filter_on_the_pending_status
    then_i_see_the_pending_question

    when_i_filter_on_the_success_status
    then_i_see_the_success_question

    when_i_clear_the_filters
    then_i_see_all_the_questions

    when_i_reorder_the_questions
    then_i_see_the_ordering_has_changed

    when_i_search_for_a_question
    then_i_see_questions_related_to_my_search

    when_i_clear_the_filters
    and_i_filter_on_questions_created_via_the_api
    then_i_see_question_created_via_the_api

    when_i_clear_the_filters
    and_i_search_for_recent_questions
    then_i_see_the_recent_questions

    when_i_clear_the_filters
    and_i_search_for_old_questions
    then_i_see_the_old_question

    when_i_clear_the_filters
    and_i_filter_by_questions_with_useful_answers
    then_i_see_the_useful_question

    when_i_clear_the_filters
    and_i_filter_by_questions_with_a_specific_question_routing_label
    then_i_see_the_question_with_that_routing_label

    when_i_view_the_questions_conversation
    and_i_filter_on_the_pending_status
    then_i_see_the_pending_question
  end

  scenario "filtered by a user" do
    given_i_am_an_admin
    and_there_are_early_access_users
    and_there_are_questions_associated_with_users

    when_i_visit_the_questions_section_filtered_by_a_user
    then_i_see_that_users_details_in_the_sidebar
    and_i_see_all_the_questions_for_that_user

    when_i_search_for_a_question_from_the_user
    then_i_see_the_filtered_questions_for_that_user

    when_clear_the_search_filter
    and_i_filter_by_the_users_first_conversation
    then_i_see_the_question_from_the_first_conversation
  end

  scenario "filtered by a signon user" do
    given_i_am_an_admin
    and_there_are_signon_users
    and_there_are_questions_associated_with_signon_users

    when_i_visit_the_questions_section_filtered_by_a_signon_user
    then_i_see_that_signon_users_details_in_the_sidebar
    and_i_see_all_the_questions_for_that_signon_user

    when_i_search_for_a_question_from_the_signon_user
    then_i_see_the_filtered_questions_for_that_signon_user
  end

  def and_there_are_early_access_users
    @user = create(:early_access_user)
    @user2 = create(:early_access_user)
  end

  def and_there_are_signon_users
    @signon_user = create(:signon_user)
    @signon_user2 = create(:signon_user)
  end

  def and_there_are_questions
    conversation = build(:conversation)
    api_conversation = build(:conversation, source: :api)
    @question1 = create(:question, conversation:, message: "Hello world", created_at: 2.years.ago)
    @question2 = create(:question, message: "World", conversation:)
    @question3 = create(:question, conversation: api_conversation, message: "Greetings world", created_at: 1.minute.ago)
    answer = create(:answer, question: @question2, question_routing_label: "non_english")
    create(:answer_feedback, answer: answer, useful: true)
    create(:answer, status: :clarification, question: @question3)
  end

  def and_there_are_questions_associated_with_users
    conversation1 = build(:conversation, user: @user)
    conversation2 = build(:conversation, user: @user)
    create(:question, conversation: conversation1, message: "Hello world")
    create(:question, conversation: conversation2, message: "Greetings world")

    conversation3 = build(:conversation, user: @user2)
    create(:question, conversation: conversation3, message: "Goodbye")
  end

  def and_there_are_questions_associated_with_signon_users
    @conversation1 = build(:conversation, signon_user: @signon_user)
    conversation2 = build(:conversation, signon_user: @signon_user)
    create(:question, conversation: @conversation1, message: "Hello world")
    create(:question, conversation: conversation2, message: "Greetings world")

    conversation3 = build(:conversation, signon_user: @signon_user2)
    create(:question, conversation: conversation3, message: "Goodbye")
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_questions_section
    click_link "Questions"
  end

  def and_i_filter_on_the_pending_status
    select "Pending", from: "status"
    click_button "Filter"
  end

  def then_i_see_the_pending_question
    expect(page).to have_content(@question1.message)
    expect(page).not_to have_content(@question2.message)
  end

  def when_i_filter_on_the_success_status
    select "Answered", from: "status"
    click_button "Filter"
  end

  def then_i_see_the_success_question
    expect(page).to have_content(@question2.message)
    expect(page).not_to have_content(@question1.message)
  end

  def when_i_clear_the_filters
    click_on "Clear all filters"
  end

  def then_i_see_all_the_questions
    within(".govuk-table") do
      expect(page).to have_content(/World.*Greetings world.*Hello world./)
    end
  end

  def then_i_see_that_users_details_in_the_sidebar
    expect(page).to have_content("Filtering by user: #{@user.email}")
  end

  def then_i_see_that_signon_users_details_in_the_sidebar
    expect(page).to have_content("Filtering by API user: #{@signon_user.name}")
  end

  def and_i_see_all_the_questions_for_that_user
    within(".govuk-table") do
      expect(page).to have_content("Hello world")
      expect(page).to have_content("Greetings world")
      expect(page).not_to have_content("Goodbye")
    end
  end
  alias_method :and_i_see_all_the_questions_for_that_signon_user, :and_i_see_all_the_questions_for_that_user

  def then_i_see_the_filtered_questions_for_that_user
    within(".govuk-table") do
      expect(page).to have_content("Greetings")
      expect(page).not_to have_content("Hello")
      expect(page).not_to have_content("Goodbye")
    end
  end
  alias_method :then_i_see_the_filtered_questions_for_that_signon_user, :then_i_see_the_filtered_questions_for_that_user

  def when_clear_the_search_filter
    fill_in "search", with: ""
  end

  def and_i_filter_by_the_users_first_conversation
    select "1st", from: "conversation_id"
    click_button "Filter"
  end

  def then_i_see_the_question_from_the_first_conversation
    within(".govuk-table") do
      expect(page).to have_content("Hello world")
      expect(page).not_to have_content("Greetings world")
    end
  end

  def when_i_reorder_the_questions
    click_link "Created at"
  end

  def then_i_see_the_ordering_has_changed
    within(".govuk-table") do
      expect(page).to have_content(/Hello world.*Greetings world.*World./)
    end
  end

  def when_i_search_for_a_question
    fill_in "Search", with: "Hello"
    click_button "Filter"
  end

  def when_i_search_for_a_question_from_the_user
    fill_in "Search", with: "Greetings"
    click_button "Filter"
  end
  alias_method :when_i_search_for_a_question_from_the_signon_user, :when_i_search_for_a_question_from_the_user

  def then_i_see_questions_related_to_my_search
    expect(page).to have_content(@question1.message)
    expect(page).not_to have_content(@question2.message)
    expect(page).not_to have_content(@question3.message)
  end

  def and_i_filter_on_questions_created_via_the_api
    select "API", from: "source"
    click_button "Filter"
  end

  def then_i_see_question_created_via_the_api
    expect(page).to have_content(@question3.message)
    expect(page).not_to have_content(@question1.message)
    expect(page).not_to have_content(@question2.message)
  end

  def and_i_search_for_recent_questions
    within "#start_date" do
      fill_in "Day", with: 1
      fill_in "Month", with: 1
      fill_in "Year", with: 1.year.ago.year
    end
    click_button "Filter"
  end

  def then_i_see_the_recent_questions
    expect(page).to have_content(@question2.message)
    expect(page).to have_content(@question3.message)
    expect(page).not_to have_content(@question1.message)
  end

  def and_i_search_for_old_questions
    within "#end_date" do
      fill_in "Day", with: 1
      fill_in "Month", with: 1
      fill_in "Year", with: 1.year.ago.year
    end
    click_button "Filter"
  end

  def then_i_see_the_old_question
    expect(page).to have_content(@question1.message)
    expect(page).not_to have_content(@question2.message)
    expect(page).not_to have_content(@question3.message)
  end

  def and_i_filter_by_questions_with_useful_answers
    select "Useful"
    click_button "Filter"
  end

  def then_i_see_the_useful_question
    expect(page).to have_content(@question2.message)
    expect(page).not_to have_content(@question1.message)
    expect(page).not_to have_content(@question3.message)
  end

  def and_i_filter_by_questions_with_a_specific_question_routing_label
    select "Non-English", from: "question_routing_label"
    click_button "Filter"
  end

  def then_i_see_the_question_with_that_routing_label
    expect(page).to have_content(@question2.message)
    expect(page).not_to have_content(@question1.message)
    expect(page).not_to have_content(@question3.message)
  end

  def when_i_view_the_questions_conversation
    click_on @question2.message
    click_on @question2.conversation.id
  end

  def when_i_visit_the_questions_section_filtered_by_a_user
    visit admin_questions_path(user_id: @user.id)
  end

  def when_i_visit_the_questions_section_filtered_by_a_signon_user
    visit admin_questions_path(signon_user_id: @signon_user.id)
  end
end
