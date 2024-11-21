RSpec.describe "StaticController" do
  shared_examples "caches the page" do |path_method|
    context "when a user is not signed in" do
      it "sets the cache headers" do
        get public_send(path_method)

        expect(response.headers["Cache-Control"]).to eq("max-age=60, public")
        expect(response.headers["Vary"]).to eq("Cookie")
      end
    end

    context "when a user is signed in" do
      include_context "when signed in"

      it "doesn't cache the response" do
        get public_send(path_method)

        expect(response.headers["Cache-Control"]).to match(/private/)
      end
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

    include_examples "caches the page", :about_path
    include_examples "operates when public access is disabled", :about_path
  end

  describe "GET :support" do
    it "renders the view correctly" do
      get support_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include("If you have a problem accessing GOV.UK Chat")
        .and have_link("Back to start page", href: homepage_path)
    end

    include_examples "caches the page", :support_path
    include_examples "operates when public access is disabled", :support_path
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
