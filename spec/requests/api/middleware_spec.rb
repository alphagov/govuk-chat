RSpec.describe "API middleware" do
  context "when a request is made within /api/" do
    it "is configured to require bearer token auth" do
      ClimateControl.modify("GDS_SSO_MOCK_INVALID" => "true") do
        get "/api/404"
        expect_bearer_error_response(response)
      end
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

  describe "rate limits" do
    context "when a read request is made within /api/v0/conversations" do
      it "treats get, head and options as read requests with rate limits" do
        %i[get head options].each do |method|
          public_send(method, "/api/v0/conversations/404")

          expect(response).to have_http_status(:not_found)
          expect(response.headers).to include_rate_limit_headers("api-user-read")
        end
      end

      it "doesn't return end user rate limits in the headers by default" do
        get "/api/v0/conversations/404"

        expect(response).to have_http_status(:not_found)
        expect(response.headers).not_to include_rate_limit_headers("end-user-id-read")
      end

      it "does return end user rate limits if an end user id is provided" do
        get "/api/v0/conversations/404", headers: { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-456" }

        expect(response).to have_http_status(:not_found)
        expect(response.headers).to include_rate_limit_headers("end-user-id-read")
      end
    end

    context "when a write request is made within /api/v0/conversations" do
      it "treats non read requests as write requests with rate limits" do
        %i[post put patch delete].each do |method|
          public_send(method, "/api/v0/conversations/404")

          expect(response).to have_http_status(:not_found)
          expect(response.headers).to include_rate_limit_headers("api-user-write")
        end
      end

      it "doesn't return end user rate limits in the headers by default" do
        post "/api/v0/conversations/404"

        expect(response).to have_http_status(:not_found)
        expect(response.headers).not_to include_rate_limit_headers("end-user-id-write")
      end

      it "does return end user rate limits if an end user id is provided" do
        post "/api/v0/conversations/404", headers: { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-456" }

        expect(response).to have_http_status(:not_found)
        expect(response.headers).to include_rate_limit_headers("end-user-id-write")
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

  def include_rate_limit_headers(type)
    include("govuk-#{type}-ratelimit-limit",
            "govuk-#{type}-ratelimit-remaining",
            "govuk-#{type}-ratelimit-reset")
  end
end
