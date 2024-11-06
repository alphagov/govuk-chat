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

    expect(rendered).to have_selector(".govuk-header__navigation") do |navigation|
      expect(navigation)
        .to have_link("About", href: about_path)
        .and have_link("Help and support", href: support_path)
    end

    expect(rendered).not_to have_selector("[data-add-print-utility]")
  end

  context "when signed_in is true" do
    it "has a sign out link when signed_in is true" do
      render("components/chat_header", signed_in: true)

      expect(rendered).to have_selector(".govuk-header__navigation") do |navigation|
        expect(navigation).to have_link("Sign out", href: sign_out_path)
      end
    end
  end

  context "when conversation is true" do
    it "has a 'Start new chat' link" do
      render("components/chat_header", conversation: true)

      expect(rendered).to have_link("Start new chat", href: clear_conversation_path)
    end

    it "has a data-add-print-utility attribute" do
      render("components/chat_header", conversation: true)

      expect(rendered).to have_selector("[data-add-print-utility]")
    end
  end
end
