RSpec.describe "Admin::HomepageController" do
  describe "GET :index" do
    it "renders successfully" do
      get admin_homepage_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("Browse questions")
    end

    context "when public access is disabled" do
      before { Settings.instance.update(public_access_enabled: false) }

      it "renders a notice" do
        get admin_homepage_path
        expect(response.body)
          .to have_selector(".gem-c-notice", text: /Public access to chat is disabled/)
      end
    end

    context "when sign up is disabled" do
      before { Settings.instance.update(public_access_enabled: true, sign_up_enabled: false) }

      it "renders a notice" do
        get admin_homepage_path
        expect(response.body)
          .to have_selector(".gem-c-notice", text: /Sign ups are disabled/)
      end
    end

    context "when a user has the developer tools permission" do
      before do
        user = create(
          :admin_user,
          permissions: [AdminUser::Permissions::ADMIN_AREA,
                        AdminUser::Permissions::DEVELOPER_TOOLS],
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
