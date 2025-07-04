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
      .and have_selector(".app-c-conversation-sources__accuracy-warning")
      .and have_selector(".app-c-conversation-sources__details")
      .and have_selector(".app-c-conversation-sources__details-summary", text: "(links open in a new tab)")
      # The following won't be visible as the details element will be initially collapsed, but they should be present
      # in the DOM
      .and have_selector(".app-c-conversation-sources__list", visible: :hidden)
      .and have_selector(".app-c-conversation-sources__list-item", visible: :hidden)
      .and have_link("Example 1", href: "http://example.com", visible: :hidden)
      .and have_link("Example 2", href: "http://example.gov.uk", visible: :hidden)
  end
end
