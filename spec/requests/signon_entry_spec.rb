RSpec.describe "SignonEntryController" do
  describe "GET :index" do
    it "redirects users with the 'admin-area' permission to the Admin UI" do
      login_as(create(:signon_user, :admin))
      get signon_entry_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(admin_homepage_path)
    end

    it "redirects users with the 'web-chat' permission to the homepage" do
      login_as(create(:signon_user, :web_chat))
      get signon_entry_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(homepage_path)
    end

    it "redirects users with both 'admin-area' and 'web-chat' permissions to the Admin UI" do
      login_as(create(:signon_user, permissions: %w[admin-area web-chat]))

      get signon_entry_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(admin_homepage_path)
    end

    it "renders forbidden for users without the 'admin-area' or 'web-chat' permissions" do
      login_as(create(:signon_user))
      get signon_entry_path
      expect(response).to have_http_status(:forbidden)
    end

    context "when web access is disabled" do
      before { create(:settings, web_access_enabled: false) }

      it "redirects users with the 'admin-area' permission to the Admin UI" do
        login_as(create(:signon_user, :admin))

        get signon_entry_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(admin_homepage_path)
      end

      it "renders the downtime page for non-admin users with the 'web-chat' permission" do
        login_as(create(:signon_user, :web_chat))

        get signon_entry_path

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body)
          .to have_content("GOV.UK Chat is not currently available")
      end
    end
  end
end
