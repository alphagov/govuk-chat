RSpec.describe "API middleware" do
  shared_examples "rate limit applied" do |method, path, rate_limit_type, headers: {}|
    it "throttles their next request" do
      public_send(method, path, headers:)

      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers).to include("govuk-#{rate_limit_type}-ratelimit-remaining" => "0")
    end

    it "allows a request from a different user" do
      login_as(create(:signon_user))

      public_send(method, path, headers:)

      expect(response).not_to have_http_status(:too_many_requests)
    end

    it "doesn't reject a request after 1 minute" do
      travel_to(Time.current + 1.minute + 1.second) do
        public_send(method, path, headers:)

        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

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

  describe "rate limits", :rack_attack do
    describe "/api/v1/conversations read rate limits" do
      it "treats get, head and options as read requests with rate limits" do
        %i[get head options].each do |method|
          public_send(method, "/api/v1/conversations/404")

          expect(response).to have_http_status(:not_found)
          expect(response.headers).to include_rate_limit_headers("api-user-read")
        end
      end

      it "doesn't return end user rate limits in the headers by default" do
        get "/api/v1/conversations/404"

        expect(response).to have_http_status(:not_found)
        expect(response.headers).not_to include_rate_limit_headers("end-user-id-read")
      end

      it "does return end user rate limits if an end user id is provided" do
        get "/api/v1/conversations/404", headers: { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-456" }

        expect(response).to have_http_status(:not_found)
        expect(response.headers).to include_rate_limit_headers("end-user-id-read")
      end

      context "when an API user has exhausted their limit" do
        before do
          read_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME]
          allow(read_throttle).to receive(:limit).and_return(1)

          get "/api/v1/conversations/404"
        end

        include_examples "rate limit applied", :get, "/api/v1/conversations/404", "api-user-read"
      end

      context "when an end user has exhausted their limit" do
        headers = { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-123" }

        before do
          read_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_END_USER_READ_THROTTLE_NAME]
          allow(read_throttle).to receive(:limit).and_return(1)

          get "/api/v1/conversations/404", headers:
        end

        include_examples "rate limit applied", :get, "/api/v1/conversations/404", "end-user-id-read", headers:
      end
    end

    describe "/api/v1/conversations write rate limits" do
      it "treats non read requests as write requests with rate limits" do
        %i[post put patch delete].each do |method|
          public_send(method, "/api/v1/conversations/404")

          expect(response).to have_http_status(:not_found)
          expect(response.headers).to include_rate_limit_headers("api-user-write")
        end
      end

      it "doesn't return end user rate limits in the headers by default" do
        post "/api/v1/conversations/404"

        expect(response).to have_http_status(:not_found)
        expect(response.headers).not_to include_rate_limit_headers("end-user-id-write")
      end

      it "does return end user rate limits if an end user id is provided" do
        post "/api/v1/conversations/404", headers: { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-456" }

        expect(response).to have_http_status(:not_found)
        expect(response.headers).to include_rate_limit_headers("end-user-id-write")
      end

      context "when an API user has exhausted their limit" do
        before do
          write_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME]
          allow(write_throttle).to receive(:limit).and_return(1)

          post "/api/v1/conversations/404"
        end

        include_examples "rate limit applied", :post, "/api/v1/conversations/404", "api-user-write"
      end

      context "when an end user has exhausted their limit" do
        headers = { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-123" }

        before do
          write_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_END_USER_WRITE_THROTTLE_NAME]
          allow(write_throttle).to receive(:limit).and_return(1)

          post "/api/v1/conversations/404", headers:
        end

        include_examples "rate limit applied", :post, "/api/v1/conversations/404", "end-user-id-write", headers:
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
