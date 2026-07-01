RSpec.describe "Rack::Attack" do
  describe ".end_user_id" do
    it "canonicalizes whitespace in the HTTP_CHAT_END_USER_ID header" do
      req1 = Rack::Request.new(
        Rack::MockRequest.env_for(
          "/api/v1/conversations/404", { "HTTP_CHAT_END_USER_ID" => "test-user-123" }
        ),
      )
      req2 = Rack::Request.new(
        Rack::MockRequest.env_for(
          "/api/v1/conversations/404",
          { "HTTP_CHAT_END_USER_ID" => "  test-user-123  " },
        ),
      )
      expect(Rack::Attack.end_user_id(req1))
        .to eq(Rack::Attack.end_user_id(req2))
    end
  end
end
