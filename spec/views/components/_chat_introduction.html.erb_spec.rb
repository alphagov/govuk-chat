RSpec.describe "components/_chat_introduction.html.erb" do
  it "renders the chat introduction component correctly" do
    render("components/chat_introduction")

    max_days = Rails.configuration.conversations.max_question_age_days
    expect(rendered)
      .to have_selector(".app-c-chat-introduction")
      .and have_selector(".app-c-chat-introduction-title__svg-container")
      .and have_selector(".app-c-chat-introduction-title__title", text: "Get quick answers from GOV.UK Chat")
      .and have_selector(".app-c-chat-introduction-title__lead-paragraph", text: "Use GOV.UK's experimental AI tool to easily find out more about topics, services and information on GOV.UK.")
      .and have_link("Ask a question")
      .and have_selector("#info-text", text: "Your chat history will be available for #{max_days} days")
  end
end
