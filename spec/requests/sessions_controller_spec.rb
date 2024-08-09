RSpec.describe "sessions controller" do
  describe "HEAD :confirm" do
    let(:session) { create :passwordless_session }
    let(:magic_link) { magic_link_url(session.to_param, session.token) }

    before do
      allow(Passwordless::Session).to receive(:find_by)
    end

    # some mail clients make this request to check a link is safe
    it "returns head: OK" do
      head magic_link
      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end

    # We don't want to sign-in the user in this situation
    it "does nothing else" do
      head magic_link
      expect(Passwordless::Session).not_to have_received(:find_by)
    end
  end

  describe "GET :confirm" do
    let(:magic_link) { magic_link_url(session.to_param, session.token) }

    context "with a valid magic link" do
      let(:session) { create :passwordless_session }

      it "allows access" do
        get magic_link
        expect(response).to redirect_to(chat_path)
      end

      context "with a stored redirect location" do
        it "redirects to the stored location" do
          get protected_path
          follow_redirect!
          get magic_link
          expect(response).to redirect_to(protected_path)
        end
      end
    end

    context "with a timed out magic link" do
      let(:session) { create :passwordless_session, :timed_out }

      it "shows session timeout page" do
        get magic_link
        expect(response.body).to include("session timed out")
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

  describe "GET :destroy" do
    let(:session) { create :passwordless_session }
    let(:magic_link) { magic_link_url(session.to_param, session.token) }

    before do
      get magic_link
      follow_redirect!
    end

    it "signs out the user" do
      get protected_path
      expect(response).to have_http_status(:ok)
      get sign_out_path
      get protected_path
      expect(response).to redirect_to(early_access_entry_path)
    end
  end
end
