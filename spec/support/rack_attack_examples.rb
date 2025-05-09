module RackAttackExamples
  shared_examples "throttles traffic from a single IP address" do |routes:, limit:, period:, request_type: nil|
    let(:route_params) { {} }
    let(:options) do
      {
        params: {},
        headers: { "HTTP_TRUE_CLIENT_IP" => ip_address },
        as: request_type.presence,
      }.compact
    end

    routes.each do |path, methods|
      methods.each do |method|
        context "when a single IP address uses it's allowance of traffic to #{method} #{path}", :rack_attack do
          let(:ip_address) { "1.2.3.4" }

          before do
            limit.times do |i|
              process(method.to_sym,
                      public_send(path, **route_params),
                      **options)
              raise "Returning too_many_requests on request #{i + 1}" if response.status == 429
            end
          end

          it "rejects the next request from that IP address" do
            process(method.to_sym,
                    public_send(path, **route_params),
                    **options)

            expect(response).to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request from a different IP address" do
            options.merge!(headers: { "REMOTE_ADDR" => "4.5.6.7", "HTTP_TRUE_CLIENT_IP": "4.5.6.7" })

            process(method.to_sym,
                    public_send(path, **route_params),
                    **options)

            expect(response).not_to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request after the time period" do
            travel_to(Time.current + period + 1.second) do
              process(method.to_sym,
                      public_send(path, **route_params),
                      **options)

              expect(response).not_to have_http_status(:too_many_requests)
            end
          end
        end
      end
    end
  end

  shared_examples "throttles traffic from a single access token" do |read_routes:, write_routes:, period:|
    let(:route_params) { {} }
    let(:auth_token) { "Bearer testtoken123" }

    before do
      read_throttle = Rack::Attack.throttles["get requests to Conversations API with token"]
      allow(read_throttle).to receive(:limit).and_return(read_routes.count)
      write_throttle = Rack::Attack.throttles["all other http method requests to Conversations API with token"]
      allow(write_throttle).to receive(:limit).and_return(write_routes.count)
    end

    [read_routes, write_routes].each do |routes|
      before do
        let(:first_routes_path) { routes.first.first.to_sym }
        let(:first_routes_method) { routes.first.second.first.to_sym }

        routes.count.times do |i|
          process(first_routes_method,
                  public_send(first_routes_path, **route_params),
                  params: {},
                  headers: { "HTTP_AUTHORIZATION" => auth_token },
                  as: :json)
          raise "Returning too_many_requests on request #{i + 1}" if response.status == 429
        end
      end

      routes.each do |path, methods|
        context "when a access token uses it's allowance", :rack_attack do
          methods.each do |method|
            it "rejects the next request to #{method} #{path}" do
              process(method.to_sym,
                      public_send(path, **route_params),
                      params: {},
                      headers: { "HTTP_AUTHORIZATION" => auth_token },
                      as: :json)

              expect(response).to have_http_status(:too_many_requests)
            end

            it "doesn't reject a request with a different token" do
              process(method.to_sym,
                      public_send(path, **route_params),
                      params: {},
                      headers: { "HTTP_AUTHORIZATION" => "Bearer testtoken456" },
                      as: :json)

              expect(response).not_to have_http_status(:too_many_requests)
            end

            it "doesn't reject a request after the time period" do
              travel_to(Time.current + period + 1.second) do
                process(method.to_sym,
                        public_send(path, **route_params),
                        params: {},
                        headers: { "HTTP_AUTHORIZATION" => auth_token },
                        as: :json)

                expect(response).not_to have_http_status(:too_many_requests)
              end
            end
          end
        end
      end
    end
  end
end
