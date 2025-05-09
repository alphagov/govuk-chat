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
      read_throttle = Rack::Attack.throttles["read requests to Conversations API with token"]
      allow(read_throttle).to receive(:limit).and_return(1)
      write_throttle = Rack::Attack.throttles["write requests to Conversations API with token"]
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
        end
      end
    end
  end

  RSpec.shared_examples "throttles traffic for a single device" do |routes:, period:|
    include_context "with rack attack helpers"
    let(:route_params) { {} }
    let(:headers) { { "HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID" => "test-device-123" } }

    before do
      read_throttle = Rack::Attack.throttles["read requests to Conversations API with device id"]
      allow(read_throttle).to receive(:limit).and_return(1)

      write_throttle = Rack::Attack.throttles["write requests to Conversations API with device id"]
      allow(write_throttle).to receive(:limit).and_return(1)
    end

    routes.each do |path, methods|
      methods.each do |method|
        context "when a user's device uses its allowance", :rack_attack do
          before { process_request(method, path, headers) }

          it "rejects the next request to #{method} #{path} with the same device ID" do
            expect_throttled_response(method, path, headers)
          end

          it "doesn't reject a request to #{method} #{path} with a different device ID" do
            expect_not_throttled_response(
              method,
              path,
              { "HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID" => "test-device-456" },
            )
          end

          it "doesn't reject a request to #{method} #{path} after the time period" do
            travel_to(Time.current + period + 1.second) do
              expect_not_throttled_response(method, path, headers)
            end
          end
        end
      end
    end
  end
end
