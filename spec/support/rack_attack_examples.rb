module RackAttackExamples
  RSpec.shared_context "with rack attack helpers" do
    def process_request(method, path, headers)
      process(method.to_sym, public_send(path, **route_params), headers: headers)
    end

    def expect_throttled_response(method, path, headers)
      process_request(method, path, headers)
      expect(response).to have_http_status(:too_many_requests)
    end

    def expect_not_throttled_response(method, path, headers)
      process_request(method, path, headers)
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  RSpec.shared_examples "throttles traffic from a single IP address" do |routes:, limit:, period:|
    include_context "with rack attack helpers"
    let(:route_params) { {} }

    routes.each do |path, methods|
      methods.each do |method|
        context "when a single IP address uses its allowance of traffic to #{method} #{path}", :rack_attack do
          let(:headers) { { "HTTP_TRUE_CLIENT_IP" => "1.2.3.4" } }

          before do
            limit.times do |i|
              process_request(method, path, headers)
              raise "Returning too_many_requests on request #{i + 1}" if response.status == 429
            end
          end

          it "rejects the next request from that IP address" do
            expect_throttled_response(method, path, headers)
          end

          it "doesn't reject a request from a different IP address" do
            expect_not_throttled_response(method, path, { "HTTP_TRUE_CLIENT_IP" => "4.5.6.7" })
          end

          it "doesn't reject a request after the time period" do
            travel_to(Time.current + period + 1.second) do
              expect_not_throttled_response(method, path, headers)
            end
          end
        end
      end
    end
  end

  shared_examples "throttles traffic for an access token" do |routes:, period:|
    include_context "with rack attack helpers"
    let(:route_params) { {} }
    let(:headers) { { "HTTP_AUTHORIZATION" => "Bearer testtoken123" } }

    before do
      read_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME]
      allow(read_throttle).to receive(:limit).and_return(1)
      write_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME]
      allow(write_throttle).to receive(:limit).and_return(1)
    end

    routes.each do |path, methods|
      methods.each do |method|
        context "when an access token exhausts its allowance", :rack_attack do
          before { process_request(method, path, headers) }

          it "rejects the next request to #{method} #{path} using the same token" do
            expect_throttled_response(method, path, headers)
          end

          it "normalises Bearer tokens with different formats" do
            [
              "bearer testtoken123",
              "BEARER testtoken123",
              " Bearer testtoken123",
              "Bearer testtoken123 ",
            ].each do |auth_value|
              process_request(method, path, { "HTTP_AUTHORIZATION" => auth_value })
              expect(response).to have_http_status(:too_many_requests)
            end
          end

          it "doesn't reject a request to #{method} #{path} using a different token" do
            expect_not_throttled_response(
              method,
              path,
              { "HTTP_AUTHORIZATION" => "Bearer testtoken456" },
            )
          end

          it "doesn't reject a request to #{method} #{path} after the time period" do
            travel_to(Time.current + period + 1.second) do
              expect_not_throttled_response(method, path, headers)
            end
          end

          it "returns rate limit details in the headers" do
            travel_to(Time.zone.local(2000, 1, 1)) do
              process_request(method, path, headers)

              expect(response.headers.keys)
                .to include(
                  a_string_matching(/govuk-api-user-(read|write)-ratelimit-limit/),
                  a_string_matching(/govuk-api-user-(read|write)-ratelimit-remaining/),
                  a_string_matching(/govuk-api-user-(read|write)-ratelimit-reset/),
                )
            end
          end
        end
      end
    end
  end

  RSpec.shared_examples "throttles traffic for a single user ID" do |routes:, period:|
    include_context "with rack attack helpers"
    let(:route_params) { {} }
    let(:headers) { { "HTTP_GOVUK_CHAT_CLIENT_USER_ID" => "test-user-123" } }

    before do
      read_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_CLIENT_USER_READ_THROTTLE_NAME]
      allow(read_throttle).to receive(:limit).and_return(1)

      write_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_CLIENT_USER_WRITE_THROTTLE_NAME]
      allow(write_throttle).to receive(:limit).and_return(1)
    end

    routes.each do |path, methods|
      methods.each do |method|
        context "when a user ID uses its allowance", :rack_attack do
          before { process_request(method, path, headers) }

          it "rejects the next request to #{method} #{path} with the same user ID" do
            expect_throttled_response(method, path, headers)
          end

          it "doesn't reject a request to #{method} #{path} with a different user ID" do
            expect_not_throttled_response(
              method,
              path,
              { "HTTP_GOVUK_CHAT_CLIENT_USER_ID" => "test-user-456" },
            )
          end

          it "doesn't reject a request to #{method} #{path} after the time period" do
            travel_to(Time.current + period + 1.second) do
              expect_not_throttled_response(method, path, headers)
            end
          end

          it "returns rate limit details in the headers" do
            travel_to(Time.zone.local(2000, 1, 1)) do
              process_request(method, path, headers)

              expect(response.headers.keys)
                .to include(
                  a_string_matching(/govuk-client-user-id-(read|write)-ratelimit-limit/),
                  a_string_matching(/govuk-client-user-id-(read|write)-ratelimit-remaining/),
                  a_string_matching(/govuk-client-user-id-(read|write)-ratelimit-reset/),
                )
            end
          end
        end
      end
    end
  end
end
