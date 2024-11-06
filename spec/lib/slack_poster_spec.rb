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

      it "posts a message to the Slack channel" do
        user = create(:early_access_user)

        ClimateControl.modify(AI_SLACK_CHANNEL_WEBHOOK_URL: "https://slack.com/webhook") do
          expect(slack_poster).to receive(:send_message).with(
            "A new user has been shadow banned. [View user](http://chat.dev.gov.uk/admin/early-access-users/#{user.id})",
          )
          described_class.shadow_ban_notification(user.id)
        end
      end
    end
  end
end
