RSpec.describe "Navigation bar" do
  describe "Settings navigation item" do
    it "renders an item which links to the Settings when the user has the admin-area-settings permission" do
      login_as(create(:signon_user, :admin_area_settings))
      get admin_homepage_path

      expect(response.body)
        .to have_selector(".govuk-service-navigation__item", text: "Settings")
        .and have_link("Settings", href: admin_settings_path)
    end

    it "doesn't render an item for Settings when the user doesn't have the admin-area-settings permission" do
      login_as(create(:signon_user, :admin))
      get admin_homepage_path
      expect(response.body)
        .not_to have_selector(".govuk-service-navigation__item", text: "Settings")
    end
  end
end
