RSpec.describe "Slack tasks" do
  describe "slack:test_shadow_ban_notification" do
    let(:task_name) { "slack:test_shadow_ban_notification" }

    before { Rake::Task[task_name].reenable }

    it "notifies Slack" do
      expect(SlackPoster)
        .to receive(:shadow_ban_notification)
        .with(instance_of(String), test_mode: true)

      Rake::Task[task_name].invoke
    end
  end
end
