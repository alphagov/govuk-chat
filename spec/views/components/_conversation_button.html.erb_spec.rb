RSpec.describe "components/_conversation_button.html.erb" do
  it "renders the conversation button component correctly" do
    render("components/conversation_button", {
      text: "Button",
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-button.govuk-button")
      .and have_selector(".app-c-conversation-button.govuk-button", text: "Button")
  end

  it "renders the conversation button start variant correctly" do
    render("components/conversation_button", {
      text: "Start button",
      start: true,
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-button.govuk-button--start")
      .and have_selector(".app-c-conversation-button.govuk-button--start", text: "Start button")
  end

  it "renders the conversation button submit variant correctly" do
    render("components/conversation_button", {
      text: "Submit button",
      submit: true,
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-button.govuk-button")
      .and have_selector(".app-c-conversation-button.govuk-button.app-c-conversation-button--submit", text: "Submit button")
  end

  it "renders an anchor tag if href is set" do
    render("components/conversation_button", {
      text: "Link button",
      href: "www.example.co.uk",
    })

    expect(rendered)
      .to have_selector("a.app-c-conversation-button.govuk-button")
  end

  it "renders rel attribute correctly" do
    render("components/conversation_button", {
      text: "Button",
      rel: "external",
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-button.govuk-button[rel='external']")
  end

  it "renders with aria-describedby" do
    render("components/conversation_button", {
      text: "Button",
      aria_describedby: "Testing aria-describedby",
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-button.govuk-button[aria-describedby='Testing aria-describedby']")
  end

  it "applies data attributes when provided" do
    render("components/conversation_button", {
      text: "Button",
      data_attributes: {
        track_category: "track-category",
        track_action: "track-action",
        track_label: "track-label",
      },
    })

    assert_select ".app-c-conversation-button.govuk-button[data-track-category='track-category']"
    assert_select ".app-c-conversation-button.govuk-button[data-track-action='track-action']"
    assert_select ".app-c-conversation-button.govuk-button[data-track-label='track-label']"
  end
end
