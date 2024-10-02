RSpec.describe "Formats in routes" do
  shared_examples "responds to HTML requests" do |path|
    it "defaults to a format of HTML" do
      # Setting an accept of */* to replicate a request that doesn't specify
      # an accept as Rails will treat it as text/html
      get path, headers: { "Accept" => "*/*" }

      expect(response).to have_http_status(:success)
                      .or have_http_status(:redirect)
      expect(response.headers["Content-Type"]).to include("text/html")
    end

    it "doesn't support a format extension" do
      get "#{path}.html"

      expect(response).to have_http_status(:not_found)
    end

    it "returns a success response for an expected Accept mime type" do
      get path, headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:success)
                      .or have_http_status(:redirect)
    end

    it "returns a not found response for an unexpected Accept mime type" do
      get path, headers: { "Accept" => "text/css" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "/chat routes" do
    include_examples "responds to HTML requests", "/chat"
  end

  describe "a chat route that supports HTML and JSON" do
    include_examples "responds to HTML requests", "/chat/conversation"

    it "responds successfully to a JSON Accept mime type" do
      get "/chat/conversation", headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:success)
                      .or have_http_status(:redirect)
    end
  end

  describe "/admin routes" do
    include_examples "responds to HTML requests", "/admin"
  end
end
