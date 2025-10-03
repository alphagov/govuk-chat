RSpec.describe ProductionHostConfig do
  describe "HOSTS" do
    let(:hosts) { described_class::HOSTS }

    it "allows the production host" do
      host = "chat.publishing.service.gov.uk"
      expect(hosts.any? { host.match?(it) }).to be(true)
    end

    it "allows the integration host" do
      host = "chat.integration.publishing.service.gov.uk"
      expect(hosts.any? { host.match?(it) }).to be(true)
    end

    it "allows the staging host" do
      host = "chat.staging.publishing.service.gov.uk"
      expect(hosts.any? { host.match?(it) }).to be(true)
    end

    it "allows Heroku apps" do
      hosts = [
        "govuk-chat.herokuapp.com",
        "govuk-chat-claude.herokuapp.com",
        "govuk-chat-dependabot-b-ljtboi.herokuapp.com",
      ]
      hosts.each do |host|
        expect(hosts.any? { host.match?(it) }).to be(true)
      end
    end
  end

  describe "HOST_AUTHORIZATION" do
    let(:excluded) { described_class::HOST_AUTHORIZATION[:exclude] }

    it "excludes paths beginning with /healthcheck" do
      env = Rack::MockRequest.env_for("http://example.com/healthcheck/live")
      request = Rack::Request.new(env)
      expect(excluded.call(request)).to be(true)
    end

    it "does not exclude other paths" do
      env = Rack::MockRequest.env_for("http://example.com/chat")
      request = Rack::Request.new(env)
      expect(excluded.call(request)).to be(false)
    end
  end
end
