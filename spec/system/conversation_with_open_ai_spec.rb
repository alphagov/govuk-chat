RSpec.describe "Conversation with OpenAI" do
  include ActiveJob::TestHelper

  around do |example|
    ClimateControl.modify(
      OPENAI_ACCESS_TOKEN: "real-open-ai-access-token",
    ) do
      example.run
    end
  end

  before do
    stub_open_ai_flag_active
    stub_search_api(["Login to your tax account"])
  end

  scenario do
    when_i_visit_the_conversation_page
    and_i_enter_a_question
    then_i_see_the_answer_is_pending

    when_the_first_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_question_on_the_page
    and_i_can_see_the_first_answer

    when_i_enter_a_second_question
    then_i_see_the_answer_is_pending

    when_the_second_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_second_question_on_the_page
    and_i_can_see_the_second_answer
  end

  def stub_open_ai_flag_active
    Flipper.enable_actor(:open_ai, AnonymousUser.new("known-user"))
  end

  def when_i_visit_the_conversation_page
    visit "/chat/conversations?user_id=known-user"
  end

  # Temp - we will stub the real thing when we've built it
  def stub_search_api(result = [])
    allow(Retrieval::SearchApiV1Retriever).to receive(:call).and_return(result)
  end

  def and_i_enter_a_question
    fill_in "Enter a question", with: "How much tax should I be paying?"
    click_on "Submit"
  end

  def then_i_see_the_answer_is_pending
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_first_answer_is_generated
    stub_any_openai_chat_completion(answer: "First answer from OpenAI") do
      perform_enqueued_jobs
    end
  end

  def when_the_second_answer_is_generated
    stub_any_openai_chat_completion(answer: "Second answer from OpenAI") do
      perform_enqueued_jobs
    end
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_i_can_see_the_first_answer
    expect(page).to have_content("First answer from OpenAI")
  end

  def and_i_can_see_the_second_answer
    expect(page).to have_content("Second answer from OpenAI")
  end

  def when_i_enter_a_second_question
    fill_in "Enter a question", with: "Are you sure?"
    click_on "Submit"
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content("Are you sure?")
  end
end
