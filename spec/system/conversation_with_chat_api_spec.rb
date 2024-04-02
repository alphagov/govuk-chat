RSpec.describe "Conversation with chat-api" do
  include ActiveJob::TestHelper

  around do |example|
    ClimateControl.modify(
      CHAT_API_URL: "https://chat-api.example.com",
      CHAT_API_USERNAME: "username",
      CHAT_API_PASSWORD: "password",
    ) do
      example.run
    end
  end

  before do
    stub_chat_api
  end

  scenario do
    given_i_have_confirmed_i_understand_chat_risks
    when_i_visit_the_conversation_page
    and_i_enter_a_question
    then_i_see_the_answer_is_pending

    when_the_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_question_on_the_page
    and_i_can_see_the_answer
    and_i_can_see_the_sources

    when_i_enter_a_second_question
    then_i_see_the_answer_is_pending

    when_the_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_second_question_on_the_page
    and_i_can_see_the_answer
  end

  def stub_chat_api
    stub_request(:post, "#{ENV['CHAT_API_URL']}/govchat")
    .to_return({
      body: {
        answer: "This is a response from chat-api",
        sources: ["https://example.com", "https://example.org"],
      }.to_json,
    })
  end

  def when_i_visit_the_conversation_page
    visit new_conversation_path
  end

  def and_i_enter_a_question
    fill_in "Enter a question", with: "How much tax should I be paying?"
    click_on "Submit"
  end

  def then_i_see_the_answer_is_pending
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_answer_is_generated
    perform_enqueued_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_i_can_see_the_answer
    expect(page).to have_content("This is a response from chat-api")
  end

  def and_i_can_see_the_sources
    expect(page).to have_link("https://example.com", visible: :hidden)
    expect(page).to have_link("https://example.org", visible: :hidden)
  end

  def when_i_enter_a_second_question
    fill_in "Enter a question", with: "Are you sure?"
    click_on "Submit"
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content("Are you sure?")
  end
end
