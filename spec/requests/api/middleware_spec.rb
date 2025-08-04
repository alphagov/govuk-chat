RSpec.describe "API middleware" do
  describe "API scope" do
    it "treats requests under /api/ as API requests" do
      ClimateControl.modify("GDS_SSO_MOCK_INVALID" => "true") do
        get "/api/404"
        expect_bearer_error_response(response)
      end
    end

    it "treats requests outside /api/ as non-API requests" do
      ClimateControl.modify("GDS_SSO_MOCK_INVALID" => "true") do
        get "/other/404"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a malformed, yet normalisable, API path is requested" do
      it "is recognised as an API request" do
        ClimateControl.modify("GDS_SSO_MOCK_INVALID" => "true") do
          get "///api//404/"
          expect_bearer_error_response(response)
        end
      end
    end
  end

  def expect_bearer_error_response(response)
    # Use a 401 status and a www-authenticate to indicate a bearer token
    # error response, as we'd expect to be redirected to login and not
    # have the header for a non-bearer token request
    expect(response).to have_http_status(:unauthorized)
    expect(response.headers).to include("www-authenticate" => 'Bearer error="invalid_request"')
  end
end
