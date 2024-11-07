RSpec.describe NotifySlackWaitingListFullJob do
  describe "#perform" do
    it "triggers a Slack notification" do
      expect(SlackPoster).to receive(:waiting_list_full)
      described_class.new.perform
    end
  end
end
