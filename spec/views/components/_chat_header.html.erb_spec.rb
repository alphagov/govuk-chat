RSpec.describe "components/_chat_header.html.erb" do
  it "renders the chat header component correctly" do
    render("components/chat_header", logo_href: "/chat")

    expect(rendered)
      .to have_selector(".app-c-header")
      .and have_selector(".app-c-header__tag", text: "Experimental")
      .and have_selector(".app-c-header__container")
      .and have_selector(".app-c-header-row")
      .and have_selector(".app-c-header__logo")
      .and have_selector(".app-c-header__link.app-c-header__link--homepage[href='/chat']")
      .and have_selector(".app-c-header__logotype")
      .and have_selector(".app-c-header__product-name")

    expect(rendered).not_to have_selector("[data-add-print-utility]")
  end

  it "renders the chat header with links when navigation_items are specified" do
    render("components/chat_header", {
      logo_href: "#",
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

    expect(rendered).to have_selector(".app-c-header__nav-container.app-c-header__nav-container--float-right-desktop")
      .and have_selector(".govuk-header__navigation")
      .and have_selector(".govuk-header__navigation .govuk-header__link[href='/item-1']", text: "Item 1")
      .and have_selector(".govuk-header__navigation .govuk-header__link[href='/item-2']", text: "Item 2")
      .and have_selector(".govuk-header__navigation[aria-label='Top level']")
      .and have_selector(".govuk-header__menu-button[aria-controls='navigation']", visible: :hidden)
      .and have_selector(".govuk-header__menu-button[aria-label='Show or hide Top Level Navigation']", visible: :hidden)

    expect(rendered).not_to have_selector("[data-add-print-utility]")
  end

  it "renders the chat header with a data-add-print-utility attribute when passed print_utility: true" do
    render("components/chat_header", {
      logo_href: "#",
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
      print_utility: true,
    })

    expect(rendered).to have_selector("[data-add-print-utility]")
  end
end
