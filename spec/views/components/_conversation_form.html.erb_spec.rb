RSpec.describe "components/_conversation_form.html.erb" do
  it "renders the conversation form component correctly" do
    render("components/conversation_form", {
      url: "/conversation",
      input_id: "id",
      name: "name",
      value: "Value",
    })

    expect(rendered).to have_selector('.app-c-conversation-form__form[action="/conversation"]') do |rendered_form|
      expect(rendered_form)
        .to have_selector(".app-c-conversation-form__label.govuk-visually-hidden", text: /Enter your question/)
        .and have_selector(".app-c-conversation-form__input[id=id][name=name][value=Value]")
        .and have_selector(".gem-c-hint", text: /Please limit your question/)
        .and have_selector(".govuk-error-message[hidden]", visible: :hidden)
        .and have_selector(".app-c-blue-button")
    end

    expect(rendered).to have_link("Share your feedback (opens in a new tab)")
  end

  it "includes a conversation id if one is provided" do
    conversation_id = SecureRandom.uuid
    render("components/conversation_form", {
      url: "/conversation",
      name: "name",
      conversation_id:,
    })

    expect(rendered)
      .to have_link("Share your feedback (opens in a new tab)", href: /\?conversation=#{conversation_id}/)
  end

  it "includes data attributes of server side validation parameters" do
    render("components/conversation_form", {
      url: "/conversation",
      input_id: "id",
      name: "name",
      value: "Value",
    })

    presence_error_message = Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE.gsub("\'", "\\\\'")

    expect(rendered)
      .to have_selector(".app-c-conversation-form[data-presence-error-message='#{presence_error_message}']")
  end

  it "renders error messages when there is a problem" do
    render("components/conversation_form", {
      url: "/conversation",
      input_id: "id",
      name: "name",
      error_items: [
        {
          text: "Error 1",
        },
      ],
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-form .govuk-error-message:not([hidden])", text: /Error:\s+Error 1/)
      .and have_selector(".app-c-conversation-form__input[aria-describedby~=id-error]")
  end
end
