RSpec.describe "StaticController" do
  shared_examples "caches the page" do |path_method|
    it "sets the cache headers" do
      get public_send(path_method)

      expect(response.headers["Cache-Control"]).to eq("max-age=60, public")
      expect(response.headers["Vary"]).to eq("Cookie")
    end
  end

  shared_examples "operates when public access is disabled" do |path_method|
    context "when public access is disabled" do
      before { Settings.instance.update!(public_access_enabled: false) }

      it "returns a success despite the status" do
        get public_send(path_method)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET :about" do
    it "renders the view correctly" do
      get about_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include("How GOV.UK Chat works")
        .and have_link("Back to start page", href: homepage_path)
    end

    context "when public access is enabled" do
      before { Settings.instance.update!(public_access_enabled: true) }

      it "renders the support link correctly" do
        get about_path
        expect(response.body)
          .to have_link("get help and support with GOV.UK Chat", href: support_path)
      end
    end

    context "when public access is disabled" do
      before { Settings.instance.update!(public_access_enabled: false) }

      it "renders the support link correctly" do
        get about_path
        expect(response.body)
          .to have_link(
            "get help and support with GOV.UK Chat",
            href: "https://surveys.publishing.service.gov.uk/s/govuk-chat-support/",
          )
      end
    end

    include_examples "caches the page", :about_path
    include_examples "operates when public access is disabled", :about_path
  end

  describe "GET :support" do
    context "when public access is enabled" do
      before { Settings.instance.update!(public_access_enabled: true) }

      it "renders the view correctly" do
        get support_path
        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to include("If you have a problem accessing GOV.UK Chat")
          .and have_link("Back to start page", href: homepage_path)
      end

      include_examples "caches the page", :support_path
    end

    context "when public access is disabled" do
      before { Settings.instance.update!(public_access_enabled: false, downtime_type: :temporary) }

      it "returns a :service_unavailable status code" do
        get support_path
        expect(response).to have_http_status(:service_unavailable)
      end

      it "renders the unavailable template" do
        get support_path
        expect(response.body).to include("GOV.UK Chat is not currently available")
      end
    end
  end

  describe "GET :accessibility" do
    it "renders the view correctly" do
      get accessibility_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include("How accessible this website is")
        .and have_link("Back to start page", href: homepage_path)
    end

    include_examples "caches the page", :accessibility_path
    include_examples "operates when public access is disabled", :accessibility_path
  end
end
