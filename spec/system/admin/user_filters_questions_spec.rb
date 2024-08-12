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
    and_i_search_for_recent_questions
    then_i_see_the_recent_question

    when_i_clear_the_filters
    and_i_search_for_old_questions
    then_i_see_the_old_question

    when_i_clear_the_filters
    and_i_filter_by_questions_with_useful_answers
    then_i_see_the_useful_question

    when_i_view_the_questions_conversation
    and_i_filter_on_the_pending_status
    then_i_see_the_pending_question
  end

  def and_there_are_questions
    conversation = build(:conversation)
    @question1 = create(:question, conversation:, message: "Hello world", created_at: 2.years.ago)
    @question2 = create(:question, :with_answer, message: "World", conversation:)
    create(:answer_feedback, answer: @question2.answer, useful: true)
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
    select "Success", from: "status"
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
      expect(page).to have_content(/World.*Hello world./)
    end
  end

  def when_i_reorder_the_questions
    click_link "Created at"
  end

  def then_i_see_the_ordering_has_changed
    within(".govuk-table") do
      expect(page).to have_content(/Hello world.*World./)
    end
  end

  def when_i_search_for_a_question
    fill_in "Search", with: "Hello"
    click_button "Filter"
  end

  def then_i_see_questions_related_to_my_search
    expect(page).to have_content(@question1.message)
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

  def then_i_see_the_recent_question
    expect(page).to have_content(@question2.message)
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
  end

  def and_i_filter_by_questions_with_useful_answers
    select "Useful"
    click_button "Filter"
  end

  def then_i_see_the_useful_question
    expect(page).to have_content(@question2.message)
    expect(page).not_to have_content(@question1.message)
  end

  def when_i_view_the_questions_conversation
    click_on @question2.message
    click_on @question2.conversation.id
  end
end
