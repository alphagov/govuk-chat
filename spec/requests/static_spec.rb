RSpec.describe "StaticController" do
  shared_examples "caches the page for 5 minutes" do |path_method|
    it "sets the cache headers to 5 mins" do
      get public_send(path_method)

      expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
    end
  end

  shared_examples "skips regenerating session" do |path_method|
    it "skips regenerating session so the resource can be cached" do
      # create a session
      get show_conversation_path
      expect(response.cookies.keys).to include("_govuk_chat_session")

      get public_send(path_method)
      expect(response.cookies).to be_empty
    end
  end

  describe "GET :about" do
    it "renders the view correctly" do
      get about_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("How GOV.UK Chat works")
    end

    include_examples "caches the page for 5 minutes", :about_path
    include_examples "skips regenerating session", :about_path
  end

  describe "GET :support" do
    it "renders the view correctly" do
      get support_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("If you have a problem accessing GOV.UK Chat")
    end

    include_examples "caches the page for 5 minutes", :support_path
    include_examples "skips regenerating session", :support_path
  end

  describe "GET :accessibility" do
    it "renders the view correctly" do
      get accessibility_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Accessibilty heading one")
    end

    include_examples "caches the page for 5 minutes", :accessibility_path
    include_examples "skips regenerating session", :accessibility_path
  end
end
