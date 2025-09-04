RSpec.describe NotifySlackApiUserRateLimitWarningJob do
  it_behaves_like "a job in queue", "default"

  describe "#perform" do
    it "triggers a Slack notification" do
      expect(SlackPoster).to receive(:api_user_rate_limit_warning).with(
        signon_name: "API User 1",
        percentage_used: 90,
        request_type: "read",
      )
      described_class.new.perform("API User 1", 90, "read")
    end
  end
end
