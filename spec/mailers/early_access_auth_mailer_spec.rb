RSpec.describe EarlyAccessAuthMailer do
  let(:mailer) { described_class }

  describe ".access_granted" do
    let(:user) { create(:early_access_user) }
    let(:session) { create(:passwordless_session, authenticatable: user) }
    let(:email) { mailer.access_granted(session) }

    it_behaves_like "sets reply_to_id"

    it "has the subject of 'You can now access GOV.UK Chat'" do
      expect(email.subject).to eq("You can now access GOV.UK Chat")
    end

    it "contains a magic link to sign in" do
      expect(email.body).to include(magic_link_url(session.to_param, session.token))
    end

    it "contains a link to the homepage" do
      expect(email.body).to include(homepage_url)
    end

    it "contains a link to unsubscribe" do
      expect(email.body).to include(early_access_user_unsubscribe_url(user.id, user.unsubscribe_token))
    end
  end

  describe ".waitlist" do
    let(:user) { create(:waiting_list_user) }
    let(:email) { mailer.waitlist(user) }
    let(:id) { user.id }
    let(:token) { user.unsubscribe_token }

    it_behaves_like "sets reply_to_id"

    it "has the subject of 'Thanks for joining the waitlist'" do
      expect(email.subject).to eq("You're on the waitlist for GOV.UK Chat")
    end

    it "informs the user we will email then when they can access chat" do
      expect(email.body).to include("Please check your emails regularly")
    end

    it "includes a link to unsubscribe" do
      expect(email.body).to include(waiting_list_user_unsubscribe_url(id:, token:))
    end
  end
end
