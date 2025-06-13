RSpec.describe "Admin::HomepageController" do
  describe "GET :index" do
    it "renders successfully" do
      get admin_homepage_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("Browse questions")
    end

    context "when api access is disabled" do
      before do
        Settings.instance.update!(api_access_enabled: false)
        login_as(create(:signon_user, :admin))
      end

      it "renders a notice" do
        get admin_homepage_path
        expect(response.body)
          .to have_selector(".gem-c-notice", text: /API access to chat is disabled/)
      end

      it "informs users to contact a developer to update the setting" do
        get admin_homepage_path
        expect(response.body).to have_content("Please contact a developer to enable API access.")
      end

      context "when the user has the admin-area-settings permission" do
        it "renders a link to the settings page" do
          login_as(create(:signon_user, :admin_area_settings))
          get admin_homepage_path
          expect(response.body)
            .to have_content("This can be changed in settings.")
            .and have_link("settings", href: admin_settings_path)
        end
      end
    end

    context "when a user has the developer tools permission" do
      before do
        user = create(
          :signon_user,
          permissions: [SignonUser::Permissions::ADMIN_AREA,
                        SignonUser::Permissions::DEVELOPER_TOOLS],
        )
        login_as(user)
      end

      it "renders a link to sidekiq" do
        get admin_homepage_path
        expect(response.body)
          .to have_link("Sidekiq", href: "/sidekiq")
      end
    end

    context "when rendered with GOVUK_ENVIRONMENT set" do
      around do |example|
        ClimateControl.modify(GOVUK_ENVIRONMENT: "development") { example.run }
      end

      it "renders a link to the infrastructure dashboard" do
        get admin_homepage_path
        expect(response.body)
          .to have_link("Infrastructure status", href: /grafana.*\/govuk-chat-technical/)
      end
    end
  end
end
