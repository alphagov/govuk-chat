RSpec.describe "StaticController" do
  shared_examples "caches the page for 5 minutes" do |path_method|
    it "sets the cache headers to 5 mins" do
      get public_send(path_method)

      expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
    end
  end

  shared_examples "operates when public access is disabled" do |path_method|
    before { Settings.instance.update!(public_access_enabled: false) }

    it "returns a success despite the application having public access disabled" do
      get public_send(path_method)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET :about" do
    it "renders the view correctly" do
      get about_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("How GOV.UK Chat works")
    end

    include_examples "caches the page for 5 minutes", :about_path
    include_examples "operates when public access is disabled", :about_path
  end

  describe "GET :support" do
    it "renders the view correctly" do
      get support_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("If you have a problem accessing GOV.UK Chat")
    end

    include_examples "caches the page for 5 minutes", :support_path
    include_examples "operates when public access is disabled", :support_path
  end

  describe "GET :accessibility" do
    it "renders the view correctly" do
      get accessibility_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Accessibilty heading one")
    end

    include_examples "caches the page for 5 minutes", :accessibility_path
    include_examples "operates when public access is disabled", :accessibility_path
  end
end
