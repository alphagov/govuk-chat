RSpec.describe "components/_blue_button.html.erb" do
  it "renders the blue button component correctly" do
    render("components/blue_button", {
      text: "Button",
    })

    expect(rendered)
      .to have_selector(".app-c-blue-button.govuk-button")
      .and have_selector(".app-c-blue-button.govuk-button", text: "Button")
  end

  it "renders the blue button start variant correctly" do
    render("components/blue_button", {
      text: "Start button",
      start: true,
    })

    expect(rendered)
      .to have_selector(".app-c-blue-button.govuk-button--start")
      .and have_selector(".app-c-blue-button.govuk-button--start", text: "Start button")
  end

  it "renders the blue button conversation form variant correctly" do
    render("components/blue_button", {
      text: "Submit button",
      conversation_form_button: true,
    })

    expect(rendered)
      .to have_selector(".app-c-blue-button.govuk-button")
      .and have_selector(".app-c-blue-button.govuk-button.app-c-blue-button--conversation-form.js-conversation-form-button", text: "Submit button")
  end

  it "renders an anchor tag if href is set" do
    render("components/blue_button", {
      text: "Link button",
      href: "www.example.co.uk",
    })

    expect(rendered)
      .to have_selector("a.app-c-blue-button.govuk-button")
  end

  it "renders with aria-describedby" do
    render("components/blue_button", {
      text: "Button",
      aria_describedby: "Testing aria-describedby",
    })

    expect(rendered)
      .to have_selector(".app-c-blue-button.govuk-button[aria-describedby='Testing aria-describedby']")
  end

  it "applies data attributes when provided" do
    render("components/blue_button", {
      text: "Button",
      data_attributes: {
        track_category: "track-category",
        track_action: "track-action",
        track_label: "track-label",
      },
    })

    expect(rendered)
      .to have_selector(".app-c-blue-button[data-track-category='track-category']")
      .and have_selector(".app-c-blue-button[data-track-action='track-action']")
      .and have_selector(".app-c-blue-button[data-track-label='track-label']")
  end
end
