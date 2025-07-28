module RackAttackExamples
  RSpec.shared_context "with rack attack helpers" do
    def process_request(method, path, headers = {})
      process(method.to_sym, public_send(path, **route_params), headers: headers)
    end

    def expect_throttled_response(method, path, headers = {})
      process_request(method, path, headers)
      expect(response).to have_http_status(:too_many_requests)
    end

    def expect_not_throttled_response(method, path, headers = {})
      process_request(method, path, headers)
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  shared_examples "throttles traffic for a signon user" do |routes:, period:|
    include_context "with rack attack helpers"
    let(:route_params) { {} }

    before do
      read_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME]
      allow(read_throttle).to receive(:limit).and_return(1)
      write_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME]
      allow(write_throttle).to receive(:limit).and_return(1)
    end

    routes.each do |path, methods|
      methods.each do |method|
        context "when a signon user exhausts their allowance", :rack_attack do
          before { process_request(method, path) }

          it "rejects the next request to #{method} #{path} using the same token" do
            expect_throttled_response(method, path)
          end

          it "doesn't reject a request to #{method} #{path} for a different user" do
            login_as(create(:signon_user))
            expect_not_throttled_response(
              method,
              path,
            )
          end

          it "doesn't reject a request to #{method} #{path} after the time period" do
            travel_to(Time.current + period + 1.second) do
              expect_not_throttled_response(method, path)
            end
          end
        end

        it "returns rate limit details in the headers" do
          process_request(method, path)

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

  RSpec.shared_examples "throttles traffic for a single user ID" do |routes:, period:|
    include_context "with rack attack helpers"
    let(:route_params) { {} }
    let(:headers) { { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-123" } }

    before do
      read_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_END_USER_READ_THROTTLE_NAME]
      allow(read_throttle).to receive(:limit).and_return(1)

      write_throttle = Rack::Attack.throttles[Api::RateLimit::GOVUK_END_USER_WRITE_THROTTLE_NAME]
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
              { "HTTP_GOVUK_CHAT_END_USER_ID" => "test-user-456" },
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
                  a_string_matching(/govuk-end-user-id-(read|write)-ratelimit-limit/),
                  a_string_matching(/govuk-end-user-id-(read|write)-ratelimit-remaining/),
                  a_string_matching(/govuk-end-user-id-(read|write)-ratelimit-reset/),
                )
            end
          end
        end
      end
    end
  end
end
