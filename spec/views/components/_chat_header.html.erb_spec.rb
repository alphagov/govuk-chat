RSpec.describe "components/_chat_header.html.erb" do
  it "renders the chat header component correctly" do
    render("components/chat_header")

    expect(rendered)
      .to have_selector(".app-c-header")
      .and have_selector(".app-c-header__tag", text: "Experimental")
      .and have_selector(".app-c-header__logo")
      .and have_selector(".app-c-header__link.app-c-header__link--homepage[href='#{homepage_path}']")
      .and have_selector(".app-c-header__logotype")
      .and have_selector(".app-c-header__product-name")
  end

  context "when conversation is true" do
    it "has a 'Clear chat' link that has a focusable only modifier" do
      render("components/chat_header", conversation: true)

      expect(rendered).to have_selector(
        "a.app-c-header__clear-chat.app-c-header__clear-chat--focusable-only[href='#{clear_conversation_path}']",
        text: "Clear chat",
      )
    end

    it "doesn't have a focusable only modifier if active_conversation is true" do
      render("components/chat_header", conversation: true, active_conversation: true)

      expect(rendered).to have_selector(
        "a.app-c-header__clear-chat:not(.app-c-header__clear-chat--focusable-only)[href='#{clear_conversation_path}']",
        text: "Clear chat",
      )
    end
  end
end
