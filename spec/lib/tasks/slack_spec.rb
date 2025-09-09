RSpec.describe "Slack tasks" do
  describe "slack:send_test_message" do
    let(:task_name) { "slack:send_test_message" }

    before { Rake::Task[task_name].reenable }

    it "notifies Slack with a given message" do
      expect(SlackPoster).to receive(:test_message).with("The message")

      Rake::Task[task_name].invoke("The message")
    end

    it "notifies Slack with a default message" do
      expect(SlackPoster).to receive(:test_message).with("Verifying we can post to Slack ✅")

      Rake::Task[task_name].invoke
    end
  end

  describe "slack:send_previous_days_activity" do
    let(:task_name) { "slack:send_previous_days_activity" }

    before { Rake::Task[task_name].reenable }

    it "notifies Slack with a given message" do
      ClimateControl.modify(AI_SLACK_CHANNEL_WEBHOOK_URL: "https://slack.com/webhook") do
        request = stub_request(:post, "https://slack.com/webhook")
                    .with(body: { "payload" => /Yesterday GOV.UK Chat API received 0 questions/ })
                    .to_return(status: 200, body: "", headers: {})

        Rake::Task[task_name].invoke

        expect(request).to have_been_made
      end
    end
  end
end
