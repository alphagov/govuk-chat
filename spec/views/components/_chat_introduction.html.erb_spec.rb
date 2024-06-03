RSpec.describe "components/_chat_introduction.html.erb" do
  it "renders the chat introduction component correctly" do
    render("components/chat_introduction")

    max_days = Rails.configuration.conversations.max_question_age_days
    expect(rendered)
      .to have_selector(".app-c-chat-introduction")
      .and have_selector(".app-c-chat-introduction__svg-container")
      .and have_selector(".app-c-chat-introduction__title", text: "GOV.UK Chat")
      .and have_selector(".app-c-chat-introduction__lead-paragraph", text: "An experimental new way to find answers to your business questions, powered by AI")
      .and have_selector("#info-text", text: "Your chat will be stored on this browser for #{max_days} days after your last message.")
  end
end
