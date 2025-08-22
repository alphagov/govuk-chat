RSpec.describe "ErrorController" do
  shared_examples "an error response" do |code, status, page_title, json_message: page_title|
    title = "code #{status.to_s.titleize}"
    it "returns a #{title} response" do
      get "/#{code}"
      expect(response).to have_http_status(status)
      expect(response.body).to have_selector("h1", text: page_title)
      expect(response.headers["No-Fallback"]).to eq "true"
    end

    context "when the request format is JSON" do
      it "returns a JSON response with a #{title} status code" do
        get "/#{code}", params: { format: :json }
        expect(response).to have_http_status(status)
      end

      it "returns a JSON response with the correct error message" do
        get "/#{code}", params: { format: :json }
        expect(JSON.parse(response.body)).to eq({ "message" => json_message })
      end
    end
  end

  describe "/400" do
    it_behaves_like "an error response",
                    400,
                    :bad_request,
                    "Sorry, there is a problem",
                    json_message: "Bad request"
  end

  describe "/403" do
    it_behaves_like "an error response",
                    403,
                    :forbidden,
                    "Sorry, you do not have access to the page",
                    json_message: "Forbidden"
  end

  describe "/404" do
    it_behaves_like "an error response",
                    404,
                    :not_found,
                    "Page not found",
                    json_message: "Not found"
  end

  describe "/422" do
    it_behaves_like "an error response",
                    422,
                    :unprocessable_content,
                    "Sorry, there is a problem",
                    json_message: "Unprocessable entity"
  end

  describe "/429" do
    it_behaves_like "an error response",
                    429,
                    :too_many_requests,
                    "Sorry, there is a problem",
                    json_message: "Too many requests"
  end

  describe "/500" do
    it_behaves_like "an error response",
                    500,
                    :internal_server_error,
                    "Sorry, there is a problem with GOV.UK Chat",
                    json_message: "Internal server error"
  end
end
