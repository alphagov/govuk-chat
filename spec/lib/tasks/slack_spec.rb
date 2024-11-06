RSpec.describe "Slack tasks" do
  describe "slack:test_shadow_ban_notification" do
    let(:task_name) { "slack:test_shadow_ban_notification" }

    before { Rake::Task[task_name].reenable }

    it "raises an error if no user exists" do
      expect { Rake::Task[task_name].invoke }
        .to raise_error("Couldn't find user")
    end

    it "notifies Slack" do
      user = create(:early_access_user)

      expect(SlackPoster).to receive(:shadow_ban_notification).with(user.id)

      Rake::Task[task_name].invoke
    end
  end
end
