RSpec.describe "components/_chat_introduction.html.erb" do
  it "renders the chat introduction component correctly" do
    render("components/chat_introduction")

    max_days = Rails.configuration.conversations.max_question_age_days
    expect(rendered)
      .to have_selector(".app-c-chat-introduction")
      .and have_selector(".app-c-chat-introduction__svg-container")
      .and have_selector(".app-c-chat-introduction__title", text: "GOV.UK Chat")
      .and have_selector(".app-c-chat-introduction__lead-paragraph", text: "An experimental new way to find answers to your business questions, powered by AI")
      .and have_link("Try GOV.UK Chat")
      .and have_selector("#info-text", text: "Your chat history will be available for #{max_days} days")
  end

  context "when early_access is true" do
    it "renders the chat introduction component with an email address form" do
      render("components/chat_introduction", early_access: true)

      expect(rendered)
        .to have_selector(".app-c-chat-introduction")
        .and have_text("Try GOV.UK Chat")
        .and have_selector(".app-c-chat-introduction__form")
        .and have_selector(".app-c-chat-introduction__form label", text: "Enter your email to sign up or get a new link for GOV.UK Chat")
        .and have_selector(".app-c-chat-introduction__form input[name='sign_in_or_up_form[email]']")
        .and have_selector(".app-c-chat-introduction__form input[aria-describedby~=info-text]")
        .and have_selector(".app-c-blue-button[type='submit']", text: "Get started")
        .and have_text("By continuing, you consent to your email being used to provide access to the tool.")
    end

    it "renders the email input with error items when 'input_error_items' are passed in" do
      render("components/chat_introduction", {
        early_access: true,
        input_error_items: [{ text: "Enter an email address" }],
      })

      expect(rendered)
        .to have_selector(".app-c-chat-introduction__form .govuk-error-message", text: /Enter an email address/)
    end

    it "sets the value of the email address input when an input_value is passed in" do
      render("components/chat_introduction", early_access: true, input_value: "test@email.com")

      expect(rendered)
        .to have_selector(".app-c-chat-introduction__form input[value='test@email.com']")
    end
  end
end
