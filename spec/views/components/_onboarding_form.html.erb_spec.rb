RSpec.describe "components/_onboarding_form.html.erb" do
  it "renders the onboarding form component for limitations correctly" do
    render("components/onboarding_form", {
      url: "/onboarding-limitations",
    })

    expect(rendered)
      .to have_selector(".app-c-onboarding-form")
      .and have_selector(".app-c-blue-button", text: "I understand")
      .and have_selector(".govuk-button--secondary", text: "Tell me more")
    expect(rendered).not_to have_selector(".govuk-link", text: "Take me to GOV.UK")
  end

  it "renders the onboarding form component for limitations correctly after 'Tell me more' is clicked" do
    render("components/onboarding_form", {
      url: "/onboarding-limitations",
      more_information: true,
    })

    expect(rendered)
      .to have_selector(".app-c-onboarding-form")
      .and have_selector(".app-c-blue-button", text: "I understand")
      .and have_selector(".govuk-link", text: "Take me to GOV.UK")
    expect(rendered).not_to have_selector(".govuk-button--secondary", text: "Tell me more")
  end

  it "renders the onboarding form component for privacy disclaimers correctly" do
    render("components/onboarding_form", {
      url: "/onboarding-privacy",
      privacy_onboarding: true,
    })

    expect(rendered)
      .to have_selector(".app-c-onboarding-form")
      .and have_selector(".app-c-blue-button", text: "Okay, start chatting")
  end
end
