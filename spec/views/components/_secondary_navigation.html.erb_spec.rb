RSpec.describe "components/_secondary_navigation.html.erb" do
  it "renders the component with the correct classes" do
    render("components/secondary_navigation", {
      aria_label: "Settings navigation",
      items: [
        {
          label: "Settings",
          href: "/settings",
          current: true,
        },
        {
          label: "Audits",
          href: "/audits",
        },
      ],
    })

    expect(rendered)
      .to have_selector(".app-c-secondary-navigation[role='navigation'][aria-label='Settings navigation']")
      .and have_selector(".app-c-secondary-navigation__list") do |list|
        expect(list)
          .to have_selector(".app-c-secondary-navigation__item", count: 2)
          .and have_selector(".app-c-secondary-navigation__item--current[aria-current='page']", text: "Settings")
          .and have_selector(".app-c-secondary-navigation__item", text: "Audits")
      end
  end

  it "applies data attributes when provided" do
    render("components/secondary_navigation", {
      aria_label: "Settings navigation",
      items: [
        {
          label: "Settings",
          href: "/settings",
          current: true,
          data_attributes: {
            tracking: "GTM-123AA",
          },
        },
        {
          label: "Audits",
          href: "/audits",
          data_attributes: {
            tracking: "GTM-123BB",
          },
        },
      ],
    })

    expect(rendered)
      .to have_selector(".app-c-secondary-navigation__list") do |list|
        expect(list)
          .to have_selector(".app-c-secondary-navigation__list-item .app-c-secondary-navigation__list-item-link[data-tracking='GTM-123AA']")
          .and have_selector(".app-c-secondary-navigation__list-item .app-c-secondary-navigation__list-item-link[data-tracking='GTM-123BB']")
      end
  end
end
