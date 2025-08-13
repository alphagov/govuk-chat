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
end
