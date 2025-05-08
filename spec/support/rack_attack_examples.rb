module RackAttackExamples
  shared_examples "throttles traffic from a single IP address" do |routes:, limit:, period:|
    let(:route_params) { {} }

    routes.each do |path, methods|
      methods.each do |method|
        context "when a single IP address uses it's allowance of traffic to #{method} #{path}", :rack_attack do
          let(:ip_address) { "1.2.3.4" }

          before do
            limit.times do |i|
              process(method.to_sym,
                      public_send(path, **route_params),
                      headers: { "HTTP_TRUE_CLIENT_IP": ip_address })
              raise "Returning too_many_requests on request #{i + 1}" if response.status == 429
            end
          end

          it "rejects the next request from that IP address" do
            process(method.to_sym,
                    public_send(path, **route_params),
                    headers: { "HTTP_TRUE_CLIENT_IP": ip_address })

            expect(response).to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request from a different IP address" do
            process(method.to_sym,
                    public_send(path, **route_params),
                    headers: { "HTTP_TRUE_CLIENT_IP": "4.5.6.7" })

            expect(response).not_to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request after the time period" do
            travel_to(Time.current + period + 1.second) do
              process(method.to_sym,
                      public_send(path, **route_params),
                      headers: { "HTTP_TRUE_CLIENT_IP": ip_address })

              expect(response).not_to have_http_status(:too_many_requests)
            end
          end
        end
      end
    end
  end

  shared_examples "throttles traffic for an access token" do |routes:, period:|
    let(:route_params) { {} }
    let(:auth_token) { "Bearer testtoken123" }

    before do
      read_throttle = Rack::Attack.throttles["read requests to Conversations API with token"]
      allow(read_throttle).to receive(:limit).and_return(1)
      write_throttle = Rack::Attack.throttles["write requests to Conversations API with token"]
      allow(write_throttle).to receive(:limit).and_return(1)
    end

    routes.each do |path, methods|
      methods.each do |method|
        before do
          process(method.to_sym,
                  public_send(path, **route_params),
                  headers: { "HTTP_AUTHORIZATION" => auth_token })
        end

        context "when a access token uses it's allowance", :rack_attack do
          it "rejects the next request to #{method} #{path}" do
            process(method.to_sym,
                    public_send(path, **route_params),
                    headers: { "HTTP_AUTHORIZATION" => auth_token })

            expect(response).to have_http_status(:too_many_requests)
          end

          it "normalises Bearer tokens with different formats" do
            [
              "bearer testtoken123",
              "BEARER testtoken123",
              " Bearer testtoken123",
              "Bearer testtoken123 ",
            ].each do |auth_value|
              process(method.to_sym,
                      public_send(path, **route_params),
                      headers: { "HTTP_AUTHORIZATION" => auth_value })
              expect(response).to have_http_status(:too_many_requests)
            end
          end

          it "doesn't reject a request with a different token" do
            process(method.to_sym,
                    public_send(path, **route_params),
                    headers: { "HTTP_AUTHORIZATION" => "Bearer testtoken456" })

            expect(response).not_to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request after the time period" do
            travel_to(Time.current + period + 1.second) do
              process(method.to_sym,
                      public_send(path, **route_params),
                      headers: { "HTTP_AUTHORIZATION" => auth_token })

              expect(response).not_to have_http_status(:too_many_requests)
            end
          end
        end
      end
    end
  end

  RSpec.shared_examples "throttles traffic for a single device" do |routes:, period:|
    let(:route_params) { {} }
    let(:device_id) { "test-device-123" }

    before do
      read_throttle = Rack::Attack.throttles["read requests to Conversations API with device id"]
      allow(read_throttle).to receive(:limit).and_return(1)

      write_throttle = Rack::Attack.throttles["write requests to Conversations API with device id"]
      allow(write_throttle).to receive(:limit).and_return(1)
    end

    routes.each do |path, methods|
      methods.each do |method|
        before do
          process(method.to_sym,
                  public_send(path, **route_params),
                  headers: { "HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID" => device_id })
        end

        context "when a users device uses its allowance", :rack_attack do
          it "rejects the next request to #{method} #{path}" do
            process(method.to_sym,
                    public_send(path, **route_params),
                    headers: { "HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID" => device_id })

            expect(response).to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request with a different device id" do
            process(method.to_sym,
                    public_send(path, **route_params),
                    headers: { "HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID" => "test-device-456" })

            expect(response).not_to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request after the time period" do
            travel_to(Time.current + period + 1.second) do
              process(method.to_sym,
                      public_send(path, **route_params),
                      headers: { "HTTP_GOVUK_CHAT_CLIENT_DEVICE_ID" => device_id })

              expect(response).not_to have_http_status(:too_many_requests)
            end
          end
        end
      end
    end
  end
end
