module RackAttackExamples
  shared_examples "throttles traffic from a single IP address" do |routes:, limit:, period:|
    routes.each do |path, methods|
      methods.each do |method|
        context "when a single IP address uses it's allowance of traffic to #{method} #{path}", :rack_attack do
          let(:ip_address) { "1.2.3.4" }

          before do
            limit.times do |i|
              process(method.to_sym,
                      public_send(path),
                      headers: { "HTTP_TRUE_CLIENT_IP": ip_address })
              raise "Returning too_many_requests on request #{i + 1}" if response.status == 429
            end
          end

          it "rejects the next request from that IP address" do
            process(method.to_sym,
                    public_send(path),
                    headers: { "HTTP_TRUE_CLIENT_IP": ip_address })

            expect(response).to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request from a different IP address" do
            process(method.to_sym,
                    public_send(path),
                    headers: { "HTTP_TRUE_CLIENT_IP": "4.5.6.7" })

            expect(response).not_to have_http_status(:too_many_requests)
          end

          it "doesn't reject a request after the time period" do
            travel_to(Time.current + period + 1.second) do
              process(method.to_sym,
                      public_send(path),
                      headers: { "HTTP_TRUE_CLIENT_IP": ip_address })

              expect(response).not_to have_http_status(:too_many_requests)
            end
          end
        end
      end
    end
  end
end
