RSpec.describe SlackPoster do
  describe ".shadow_ban_notification" do
    it "does nothing if the Slack webhook URL is not set" do
      ClimateControl.modify(AI_SLACK_CHANNEL_WEBHOOK_URL: nil) do
        expect(Slack::Poster).not_to receive(:new)
        described_class.shadow_ban_notification(1)
      end
    end

    context "when the Slack webhook URL is set" do
      let(:slack_poster) { instance_double(Slack::Poster) }

      before do
        allow(Slack::Poster).to receive(:new).and_return(slack_poster)
      end

      around do |example|
        ClimateControl.modify(AI_SLACK_CHANNEL_WEBHOOK_URL: "https://slack.com/webhook") do
          example.run
        end
      end

      it "posts a message to the Slack channel" do
        user = create(:early_access_user)

        expect(slack_poster).to receive(:send_message).with(
          "A new user has been shadow banned. <http://chat.dev.gov.uk/admin/early-access-users/#{user.id}|View user>",
        )
        described_class.shadow_ban_notification(user.id)
      end

      it "prepends the message with a test string" do
        expect(slack_poster).to receive(:send_message).with(
          "[TEST] A new user has been shadow banned. <http://chat.dev.gov.uk/admin/early-access-users/1|View user>",
        )
        described_class.shadow_ban_notification(1, test_mode: true)
      end
    end
  end
end
