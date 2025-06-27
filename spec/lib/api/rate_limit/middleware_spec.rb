RSpec.describe Api::RateLimit::Middleware do
  let(:mock_app) { ->(_env) { [200, { "Content-Type" => "application/json" }, ["{}"]] } }
  let(:middleware) { described_class.new(mock_app) }

  describe "#call", :rack_attack do
    let(:current_time) { Time.current.to_i }

    let(:env) do
      {
        "rack.attack.throttle_data" => {
          Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME => {
            limit: 10,
            count: 3,
            period: 60,
            epoch_time: current_time,
          },
          Api::RateLimit::GOVUK_CLIENT_USER_READ_THROTTLE_NAME => {
            limit: 5,
            count: 5,
            period: 60,
            epoch_time: current_time - 50,
          },
        },
      }
    end

    it "adds correct rate limit headers to the response" do
      travel_to(Time.zone.local(2000, 1, 1)) do
        _, headers = middleware.call(env)

        expect(headers["Govuk-Api-User-Read-RateLimit-Limit"]).to eq("10")
        expect(headers["Govuk-Api-User-Read-RateLimit-Remaining"]).to eq("7")
        expect(headers["Govuk-Api-User-Read-RateLimit-Reset"]).to eq("60s")

        expect(headers["Govuk-Client-User-Id-Read-RateLimit-Limit"]).to eq("5")
        expect(headers["Govuk-Client-User-Id-Read-RateLimit-Remaining"]).to eq("0")
        expect(headers["Govuk-Client-User-Id-Read-RateLimit-Reset"]).to eq("50s")
      end
    end

    it "does not add rate limit headers if throttle_data is missing" do
      env.delete("rack.attack.throttle_data")

      _, headers = middleware.call(env)

      expect(headers.keys).not_to include(a_string_matching(/RateLimit/))
    end

    it "does not allow negative remaining requests" do
      env["rack.attack.throttle_data"][Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME][:count] = 15

      _, headers = middleware.call(env)

      expect(headers["Govuk-Api-User-Read-RateLimit-Remaining"]).to eq("0")
    end

    context "when the throttle name is not in the mapping" do
      before do
        env["rack.attack.throttle_data"].merge!(
          "unknown_throttle" => {
            limit: 10,
            count: 3,
            period: 60,
            epoch_time: current_time,
          },
        )
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with("Unknown throttle name: unknown_throttle")

        middleware.call(env)
      end

      it "still adds headers for known throttles" do
        _, headers = middleware.call(env)

        expect(headers.keys).to include(
          "Govuk-Api-User-Read-RateLimit-Limit",
          "Govuk-Api-User-Read-RateLimit-Remaining",
          "Govuk-Api-User-Read-RateLimit-Reset",
          "Govuk-Client-User-Id-Read-RateLimit-Limit",
          "Govuk-Client-User-Id-Read-RateLimit-Remaining",
          "Govuk-Client-User-Id-Read-RateLimit-Reset",
        )
      end
    end
  end
end
