RSpec.feature "Conversation with OpenAI", :sidekiq_inline do
  include ActiveJob::TestHelper

  around do |example|
    ClimateControl.modify(
      OPENAI_MODEL: "gpt-3.5-turbo",
      OPENAI_ACCESS_TOKEN: "real-open-ai-access-token",
    ) do
      example.run
    end
  end

  before do
    stub_open_ai_flag_active
    stub_search_api(["Login to your tax account"])
    chat_history = [{ role: "user", content: format_user_question("How much tax should I be paying?") }]
    stub_openai_chat_completion(chat_history, "Answer from OpenAI")
  end

  scenario do
    when_a_user_visits_conversation_page
    and_they_enter_a_question
    then_they_see_the_question_pending_page

    when_the_answer_is_generated
    and_the_user_clicks_on_the_check_answer_button
    then_they_see_their_question_on_the_page
    and_they_can_see_the_answer

    when_they_enter_a_second_question
    then_they_see_the_question_pending_page

    when_the_answer_is_generated
    and_the_user_clicks_on_the_check_answer_button
    then_they_see_their_second_question_on_the_page
    and_they_can_see_the_answer
  end

  def stub_open_ai_flag_active
    Flipper.enable_actor(:open_ai, AnonymousUser.new("known-user"))
  end

  def when_a_user_visits_conversation_page
    visit "/chat?user_id=known-user"
  end

  # Temp - we will stub the real thing when we've built it
  def stub_search_api(result = [])
    allow(Retrieval::SearchApiV1Retriever).to receive(:call).and_return(result)
  end

  def and_they_enter_a_question
    fill_in "Enter a question", with: "How much tax should I be paying?"
    click_on "Submit"
  end

  def then_they_see_the_question_pending_page
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_answer_is_generated
    perform_enqueued_jobs
  end

  def and_the_user_clicks_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_they_see_their_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_they_can_see_the_answer
    expect(page).to have_content("Answer from OpenAI")
  end

  def when_they_enter_a_second_question
    fill_in "Enter a question", with: "Are you sure?"
    click_on "Submit"
  end

  def then_they_see_their_second_question_on_the_page
    expect(page).to have_content("Are you sure?")
  end

  def format_user_question(question)
    <<~OUTPUT
      #{AnswerGeneration::Prompts::GOVUK_DESIGNER}

      Context:
      Login to your tax account

      Question:
      #{question}
    OUTPUT
  end
end
