RSpec.describe "toggling downtime with Settings.instance.public_access_enabled" do
  shared_examples "prevents access to routes" do
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

    it "sets the 'No-Fallback' header" do
      get homepage_path
      expect(response.headers["No-Fallback"]).to eq("true")
    end

    it "doesn't render the help and support link in the header of footer" do
      get homepage_path
      expect(response.body).not_to include("Help and support")
    end

    it "doesn't clobber error pages" do
      get "/404"
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when public_access_enabled is false and downtime_type is temporary" do
    before { create(:settings, public_access_enabled: false, downtime_type: :temporary) }

    it "renders service unavailable content, with a service_unavailable status" do
      get homepage_path
      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to match(/GOV.UK Chat is not currently available/)
    end

    include_examples "prevents access to routes"
  end

  context "when public_access_enabled is false and downtime_type is permanent" do
    before { create(:settings, public_access_enabled: false, downtime_type: :permanent) }

    it "renders shutdown content, with a gone status" do
      get homepage_path
      expect(response).to have_http_status(:gone)
      expect(response.body).to match(/The GOV.UK Chat trial has closed/)
    end

    include_examples "prevents access to routes"
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
