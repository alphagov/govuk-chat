RSpec.describe "early access entry point" do
  let(:early_access_user) { create :early_access_user }

  describe "POST :create" do
    it "redirects to chat" do
      post early_access_entry_path(
        form_early_access_entry: { email: early_access_user.email },
      )
      expect(response).to redirect_to(early_access_entry_email_sent_path)
    end

    it "creates a session" do
      expect {
        post early_access_entry_path(
          form_early_access_entry: { email: early_access_user.email },
        )
      }.to change(Passwordless::Session, :count).by(1)
    end

    it "sends an email" do
      expect {
        post early_access_entry_path(
          form_early_access_entry: { email: early_access_user.email },
        )
      }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
    end
  end
end
