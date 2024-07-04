RSpec.describe "components/_conversation_sources.html.erb" do
  it "renders the conversation sources component correctly" do
    render("components/conversation_sources", {
      sources: [
        {
          title: "Example 1",
          href: "http://example.com",
        },
        {
          title: "Example 2",
          href: "http://example.gov.uk",
        },
      ],
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-sources")
      .and have_selector(".app-c-warning-text")
      .and have_selector(".app-c-warning-text__opens-in-new-tab", text: "(links open in a new tab)")
      .and have_link("Example 1", href: "http://example.com")
      .and have_link("Example 2", href: "http://example.gov.uk")
  end
end
