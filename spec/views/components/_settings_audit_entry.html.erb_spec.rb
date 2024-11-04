RSpec.describe "components/_settings_audit_entry.html.erb" do
  it "renders the component correctly" do
    render("components/settings_audit_entry", {
      action: "Added 10 instant access places",
      created_at: "11:00am on 1 January 2024",
    })

    expect(rendered)
      .to have_selector(
        ".app-c-settings-audit-entry .app-c-settings-audit-entry__action",
        text: "Added 10 instant access places",
      )
      .and have_selector(
        ".app-c-settings-audit-entry .app-c-settings-audit-entry__authored",
        text: "Changed at 11:00am on 1 January 2024 by unknown user",
      )
  end

  it "renders the component correctly when an author_comment is passed in" do
    render("components/settings_audit_entry", {
      action: "Added 10 instant access places",
      created_at: "11:00am on 1 January 2024",
      author_comment: "We need more places.",
    })

    expect(rendered)
      .to have_selector(
        ".app-c-settings-audit-entry .app-c-settings-audit-entry__author_comment p.govuk-body",
        text: "We need more places.",
      )
  end

  it "renders any HTML in an author comment as text" do
    render("components/settings_audit_entry", {
      action: "Added 10 instant access places",
      created_at: "11:00am on 1 January 2024",
      author_comment: "<strong>I wondered if I could make this bold</strong>",
    })

    expect(rendered)
      .to have_selector(
        ".app-c-settings-audit-entry .app-c-settings-audit-entry__author_comment",
        text: "<strong>I wondered if I could make this bold</strong>",
      )
  end

  it "renders the component correctly when a user is passed in" do
    render("components/settings_audit_entry", {
      action: "Added 10 instant access places",
      created_at: "11:00am on 1 January 2024",
      user: "Test user",
    })

    expect(rendered)
      .to have_selector(
        ".app-c-settings-audit-entry .app-c-settings-audit-entry__authored",
        text: "Changed at 11:00am on 1 January 2024 by Test user",
      )
  end
end
