RSpec.describe Api::AuthMiddleware do
  let(:mock_app) { ->(_env) { [200, { "Content-Type" => "application/json" }, ["{}"]] } }
  let(:middleware) { described_class.new(mock_app) }

  before { allow(GDS::SSO).to receive(:authenticate_user!) }

  describe "#call" do
    context "when the path requested is within /api/" do
      it "authenticates the user with GDS SSO" do
        warden = instance_double(Warden::Proxy)
        env = { "PATH_INFO" => "/api/route", "warden" => warden }
        middleware.call(env)
        expect(GDS::SSO).to have_received(:authenticate_user!).with(warden)
      end

      it "raises an error if warden is not in the rack env" do
        expect { middleware.call({ "PATH_INFO" => "/api/route" }) }
          .to raise_error(KeyError)
      end
    end

    context "when the path requested is not within /api/" do
      it "doesn't authenticate the request" do
        middleware.call({ "PATH_INFO" => "/another-path" })
        expect(GDS::SSO).not_to have_received(:authenticate_user!)
      end
    end
  end
end
