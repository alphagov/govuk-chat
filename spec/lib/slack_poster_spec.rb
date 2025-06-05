RSpec.describe SlackPoster do
  describe "without a webhook url" do
    it "does not send a message" do
      ClimateControl.modify(AI_SLACK_CHANNEL_WEBHOOK_URL: nil) do
        expect(Slack::Poster).not_to receive(:new)
        described_class.waiting_list_full
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

    describe ".waiting_list_full" do
      it "posts a message to the Slack channel" do
        expect(slack_poster).to receive(:send_message).with(
          "The waiting list is full",
        )
        described_class.waiting_list_full
      end
    end
  end
end
