RSpec.describe EarlyAccessAuthMailer do
  let(:mailer) { described_class }

  describe ".access_granted" do
    let(:user) { create(:early_access_user) }
    let(:session) { create(:passwordless_session, authenticatable: user) }
    let(:email) { mailer.access_granted(session) }

    it "has the subject of 'You can now access GOV.UK Chat'" do
      expect(email.subject).to eq("You can now access GOV.UK Chat")
    end

    it "contains a magic link to sign in" do
      email = mailer.access_granted(session)

      expect(email.body).to include(magic_link_url(session.to_param, session.token))
    end

    it "contains a link to unsubscribe" do
      email = mailer.access_granted(session)

      expect(email.body).to include(early_access_user_unsubscribe_url(user.id, user.unsubscribe_access_token))
    end
  end

  describe ".sign_in" do
    let(:user) { create(:early_access_user) }
    let(:session) { create(:passwordless_session, authenticatable: user) }
    let(:email) { mailer.sign_in(session) }

    it "has the subject of 'Sign in'" do
      expect(email.subject).to eq("Sign in")
    end

    it "contains a magic link to sign in" do
      email = mailer.sign_in(session)

      expect(email.body).to include(magic_link_url(session.to_param, session.token))
    end
  end

  describe ".waitlist" do
    let(:user) { create(:waiting_list_user) }
    let(:email) { mailer.waitlist(user) }

    it "has the subject of 'Thanks for joining the waitlist'" do
      expect(email.subject).to eq("Thanks for joining the waitlist")
    end

    it "informs the user we will email then when they can access chat" do
      expect(email.body).to include "We will send you another email when you can access GOV.UK Chat."
    end
  end
end
