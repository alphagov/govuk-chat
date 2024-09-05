RSpec.describe "toggling downtime with Settings.instance.public_access_enabled" do
  shared_examples "prevents access to routes" do |status|
    it "renders service unavailable content, with a #{status} status" do
      get homepage_path
      expect(response).to have_http_status(status)
      expect(response.body).to match(/GOV.UK Chat is not currently available/)
    end

    it "caches the response for 1 minute" do
      get homepage_path
      expect(response.headers["Cache-Control"]).to eq("max-age=60, public")
    end

    it "skips regenerating a session so the resource can be cached" do
      # re-enable public_access_enabled so we can make a request to create a session cookie
      Settings.instance.update!(public_access_enabled: true)
      get show_conversation_path
      expect(response.cookies.keys).to include("_govuk_chat_session")
      Settings.instance.update!(public_access_enabled: false)

      get homepage_path
      expect(response.cookies).to be_empty
    end

    context "and the user is signed in" do
      before { Settings.instance.update!(public_access_enabled: true) }
      include_context "when signed in"

      it "prevents customisation of the layout based on signed in status" do
        get onboarding_limitations_path
        expect(response.body)
          .to have_selector("a.app-c-header__link[href='#{show_conversation_path}']")

        Settings.instance.update!(public_access_enabled: false)
        get onboarding_limitations_path
        expect(response.body)
          .to have_selector("a.app-c-header__link[href='#{homepage_path}']")
      end
    end
  end

  context "when public_access_enabled is false and downtime_type is temporary" do
    before { create(:settings, public_access_enabled: false, downtime_type: :temporary) }

    include_examples "prevents access to routes", :service_unavailable
  end

  context "when public_access_enabled is false and downtime_type is permanent" do
    before { create(:settings, public_access_enabled: false, downtime_type: :permanent) }

    include_examples "prevents access to routes", :gone
  end

  context "when public_access_enabled is true" do
    before { create(:settings, public_access_enabled: true) }

    it "doesn't impact routes" do
      get homepage_path
      expect(response).not_to have_http_status(:service_unavailable)
      expect(response).not_to have_http_status(:gone)
    end
  end
end
