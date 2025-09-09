RSpec.describe SlackPoster do
  describe "without a webhook url" do
    it "does not send a message" do
      ClimateControl.modify(AI_SLACK_CHANNEL_WEBHOOK_URL: nil) do
        expect(Slack::Poster).not_to receive(:new)
        described_class.test_message("The message")
      end
    end
  end

  describe "with a webhook url" do
    around do |example|
      ClimateControl.modify(AI_SLACK_CHANNEL_WEBHOOK_URL: "https://slack.com/webhook") do
        example.run
      end
    end

    let(:slack_poster) { instance_double(Slack::Poster) }

    before do
      allow(Slack::Poster).to receive(:new).and_return(slack_poster)
    end

    describe ".test_message" do
      it "sends the message prepended with a test string" do
        expect(slack_poster).to receive(:send_message).with(
          "[TEST] The message",
        )
        described_class.test_message("The message")
      end
    end

    describe ".api_user_rate_limit_warning" do
      it "posts a message to the Slack channel" do
        expect(slack_poster).to receive(:send_message).with(
          "API User 1 is reaching their API user rate limit: 80% of read requests used",
        )
        described_class.api_user_rate_limit_warning(
          signon_name: "API User 1", percentage_used: 80, request_type: "read",
        )
      end
    end

    describe ".previous_days_api_activity" do
      it "posts a message with the daily activity message" do
        activity_message = instance_double(DailyApiActivityMessage, message: "The daily activity message")
        allow(DailyApiActivityMessage).to receive(:new).and_return(activity_message)
        expect(slack_poster).to receive(:send_message).with("The daily activity message")
        described_class.previous_days_api_activity
      end
    end
  end
end
