RSpec.describe "sessions controller" do
  let(:magic_link) { magic_link_url(session.to_param, session.token) }

  context "with a valid magic link" do
    let(:session) { create :passwordless_session }

    it "allows access" do
      get magic_link
      expect(response).to redirect_to(chat_path)
    end
  end

  context "with a timed out magic link" do
    let(:session) { create :passwordless_session, :timed_out }

    it "shows session timeout page" do
      get magic_link
      expect(response).to redirect_to(session_timeout_path)
    end
  end

  context "when the magic link has been used" do
    let(:session) { create :passwordless_session, :claimed }

    it "disallows access" do
      get magic_link
      # TODO: change this to assert actual response from content designers
      expect(response.body).to include("magic link used")
    end
  end

  context "when the session doesn't exist" do
    let!(:session) { create :passwordless_session }

    before do
      session.destroy
    end

    it "disallows access" do
      get magic_link
      # TODO: change this to assert actual response from content designers
      # We don't know who the user is
      expect(response.body).to include("session not found")
    end
  end

  context "when the token doesn't match" do
    let(:session) { create :passwordless_session }

    it "disallows access" do
      get magic_link_path(session.to_param, "the-wrong-token")
      # TODO: change this to assert actual response from content designers
      # We do know who the user is maybe they messed up the link
      expect(response.body).to include("invalid token")
    end
  end
end
