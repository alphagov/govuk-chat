RSpec.describe "ErrorController" do
  shared_examples "an error response" do |code, status, page_title|
    title = "code #{status.to_s.titleize}"
    it "returns a #{title} response" do
      get "/#{code}"
      expect(response).to have_http_status(status)
      expect(response.body).to have_selector(".gem-c-title__text", text: page_title)
    end
  end

  describe "/400" do
    it_behaves_like "an error response", 400, :bad_request, "Sorry, there is a problem"
  end

  describe "/403" do
    it_behaves_like "an error response", 403, :forbidden, "Sorry, you do not have access to the page"
  end

  describe "/404" do
    it_behaves_like "an error response", 404, :not_found, "Page not found"
  end

  describe "/422" do
    it_behaves_like "an error response", 422, :unprocessable_entity, "Sorry, there is a problem"
  end

  describe "/500" do
    it_behaves_like "an error response", 500, :internal_server_error, "Sorry, there is a problem with GOV.UK Chat"
  end
end
