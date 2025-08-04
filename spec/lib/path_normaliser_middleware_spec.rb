RSpec.describe PathNormaliserMiddleware do
  let(:mock_app) { ->(_env) { [200, { "Content-Type" => "application/json" }, ["{}"]] } }
  let(:middleware) { described_class.new(mock_app) }

  describe "#call" do
    it "changes env['PATH_INFO'] value of requests with Rails compatible but un-normal paths" do
      env = { "PATH_INFO" => "//api//route/" }

      expect { middleware.call(env) }
        .to change { env["PATH_INFO"] }
        .to("/api/route")
    end

    it "doesn't change env['PATH_INFO'] for regular Rails compatible paths" do
      env = { "PATH_INFO" => "/api/route" }

      expect { middleware.call(env) }
        .not_to(change { env["PATH_INFO"] })
    end
  end
end
