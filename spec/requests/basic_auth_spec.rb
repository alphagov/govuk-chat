RSpec.describe "Basic auth" do
  context "when the application is not configured for basic auth" do
    it "returns a successful status code requesting root" do
      request_root
      expect(response).to have_http_status(:success)
    end
  end

  context "when environment variables are configured to enable basic authentication" do
    around do |example|
      ClimateControl.modify(
        BASIC_AUTH_USERNAME: "username",
        BASIC_AUTH_PASSWORD: "password",
      ) do
        example.run
      end
    end

    it "returns an unauthorized status code when credentials aren't provided" do
      request_root
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns an unauthorized status code when credentials are incorrect" do
      request_root(username: "wrong", password: "also wrong")
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns a successful status code when credentials are correct" do
      request_root(username: "username", password: "password")
      expect(response).to have_http_status(:success)
    end
  end

  context "when environment variables are configured to enable multiple basic auth logins" do
    around do |example|
      ClimateControl.modify(
        BASIC_AUTH_USERNAME_USER_1: "username_1",
        BASIC_AUTH_PASSWORD_USER_1: "password_1",
        BASIC_AUTH_USERNAME_USER_2: "username_2",
        BASIC_AUTH_PASSWORD_USER_2: "password_2",
      ) do
        example.run
      end
    end

    it "returns a successful status code when given pairs of correct credentials" do
      responses = []
      request_root(username: "username_1", password: "password_1")
      responses << response
      request_root(username: "username_2", password: "password_2")
      responses << response

      expect(responses).to all(have_http_status(:successful))
    end

    it "returns an unauthorized status code when credentials are incorrect" do
      responses = []
      request_root(username: "username_1", password: "")
      responses << response
      request_root(username: "username_1", password: "password_2") # mismatched
      responses << response

      expect(responses).to all(have_http_status(:unauthorized))
    end
  end

  def request_root(username: nil, password: nil)
    headers = if username || password
                credentials = Base64.encode64("#{username}:#{password}")
                { "Authorization" => "Basic #{credentials}" }
              else
                {}
              end

    get root_path
    # we expect the root path to be a redirect that needs following
    follow_redirect!(headers:)
  end
end
