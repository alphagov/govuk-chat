RSpec.describe "components/_chat_header.html.erb" do
  it "renders the chat header component correctly" do
    render("components/chat_header")

    expect(rendered)
      .to have_selector(".app-c-header")
      .and have_selector(".app-c-header__tag", text: "Experimental")
      .and have_selector(".app-c-header__container")
      .and have_selector(".app-c-header__logo")
      .and have_selector(".app-c-header__link.app-c-header__link--homepage")
      .and have_selector(".app-c-header__logotype")
      .and have_selector(".app-c-header__product-name")
  end

  it "renders the chat header with links when navigation_items are specified" do
    render("components/chat_header", {
      navigation_items: [
        {
          text: "Item 1",
          href: "/item-1",
        },
        {
          text: "Item 2",
          href: "/item-2",
        },
      ],
    })

    expect(rendered).to have_selector(".govuk-header__navigation")
      .and have_selector(".govuk-header__navigation .govuk-header__link[href='/item-1']", text: "Item 1")
      .and have_selector(".govuk-header__navigation .govuk-header__link[href='/item-2']", text: "Item 2")
      .and have_selector(".govuk-header__navigation[aria-label='Top level']")
  end
end
