RSpec.feature "Conversation with chat-api", :sidekiq_inline do
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
    when_a_user_visits_the_homepage
    and_they_enter_a_question
    then_they_see_their_question_on_the_page
    and_they_can_see_the_answer
    and_they_can_see_the_sources
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

  def when_a_user_visits_the_homepage
    visit root_path
  end

  def and_they_enter_a_question
    fill_in "Enter a question", with: "How much tax should I be paying?"
    click_on "Submit"
  end

  def then_they_see_their_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_they_can_see_the_answer
    expect(page).to have_content("This is a response from chat-api")
  end

  def and_they_can_see_the_sources
    expect(page).to have_link("https://example.com", visible: :hidden)
    expect(page).to have_link("https://example.org", visible: :hidden)
  end
end
