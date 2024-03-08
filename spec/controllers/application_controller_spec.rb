RSpec.describe ApplicationController, type: :controller do
  describe "#login_anon" do
    let(:user_param) { nil }
    let(:session_user_id) { nil }

    before do
      allow(controller).to receive(:user_param).and_return(user_param)
      session[:user_id] = session_user_id
      Current.user = nil
      controller.send(:login_anon)
    end

    context "when session[:user] is present and user_param is nil" do
      let(:session_user_id) { SecureRandom.uuid }

      it "sets Current.user to session[:user]" do
        controller.send(:login_anon)
        expect(Current.user.id).to eq(session_user_id)
      end
    end

    context "when session[:user] is not present" do
      it "creates a new AnonymousUser with UUID, assigns it to session[:user], and sets Current.user" do
        expect(Current.user).to be_a(AnonymousUser)
        expect(session[:user_id]).to match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/)
      end
    end

    context "when user_param is present" do
      let(:user_param) { "some-user-id" }
      let(:params) { { user: user_param } }

      it "creates a new AnonymousUser with user_param, assigns it to session[:user], and sets Current.user" do
        expect(Current.user).to be_a(AnonymousUser)
        expect(Current.user.id).to eq(user_param)
        expect(session[:user_id]).to eq(user_param)
      end
    end
  end
end
