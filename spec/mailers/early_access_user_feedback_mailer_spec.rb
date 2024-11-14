RSpec.describe EarlyAccessUserFeedbackMailer do
  let(:mailer) { described_class }

  describe ".request_feedback" do
    let(:user) { create(:early_access_user) }
    let(:email) { mailer.request_feedback(user) }

    it_behaves_like "sets reply_to_id"

    it "sets the subject" do
      expect(email.subject).to eq("Share your experience of GOV.UK Chat")
    end

    it "contains a link to the homepage" do
      expect(email.body).to include("[GOV.UK Chat](#{homepage_url})")
    end

    it "contains a link to the survey" do
      expect(email.body).to include(
        "https://surveys.publishing.service.gov.uk/s/govuk-chat-beta?user=#{user.id}&source=request_feedback_email",
      )
    end

    it "contains a link to unsubscribe" do
      expect(email.body).to include(early_access_user_unsubscribe_url(user.id, user.unsubscribe_token))
    end
  end
end
