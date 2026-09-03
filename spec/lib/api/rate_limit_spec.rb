RSpec.describe Api::RateLimit do
  describe ".conversation_write?" do
    it "returns true for creating a conversation" do
      expect(described_class.conversation_write?(request("POST", "/api/v1/conversation")))
        .to be(true)
    end

    it "returns true for updating a conversation" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}"

      expect(described_class.conversation_write?(request("PUT", path))).to be(true)
    end

    it "returns true for any API version" do
      expect(described_class.conversation_write?(request("POST", "/api/v2/conversation")))
        .to be(true)
    end

    %i[GET PUT PATCH DELETE].each do |method|
      it "returns false for a #{method} request to the create conversation path" do
        expect(described_class.conversation_write?(request(method, "/api/v1/conversation")))
          .to be(false)
      end
    end

    %i[GET POST PATCH DELETE].each do |method|
      it "returns false for a #{method} request to the update conversation path" do
        path = "/api/v1/conversation/#{SecureRandom.uuid}"

        expect(described_class.conversation_write?(request(method, path))).to be(false)
      end
    end

    it "returns false for reading the questions in a conversation" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}/questions"

      expect(described_class.conversation_write?(request("GET", path))).to be(false)
    end

    it "returns false for giving feedback on an answer" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}/answers/#{SecureRandom.uuid}/feedback"

      expect(described_class.conversation_write?(request("POST", path))).to be(false)
    end

    it "returns false for requests outside the conversations API" do
      expect(described_class.conversation_write?(request("POST", "/api/v1/something-else")))
        .to be(false)
    end
  end

  describe ".default?" do
    it "returns true for reading a conversation" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}"

      expect(described_class.default?(request("GET", path))).to be(true)
    end

    it "returns true for reading the questions in a conversation" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}/questions"

      expect(described_class.default?(request("GET", path))).to be(true)
    end

    it "returns true for giving feedback on an answer" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}/answers/#{SecureRandom.uuid}/feedback"

      expect(described_class.default?(request("POST", path))).to be(true)
    end

    it "returns false for creating a conversation" do
      expect(described_class.default?(request("POST", "/api/v1/conversation"))).to be(false)
    end

    it "returns false for updating a conversation" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}"

      expect(described_class.default?(request("PUT", path))).to be(false)
    end

    it "returns true for a conversation write path used with an unexpected method" do
      path = "/api/v1/conversation/#{SecureRandom.uuid}"

      expect(described_class.default?(request("POST", path))).to be(true)
    end

    it "returns false for requests outside the conversations API" do
      expect(described_class.default?(request("GET", "/api/v1/something-else"))).to be(false)
    end
  end

  def request(method, path)
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end
end
