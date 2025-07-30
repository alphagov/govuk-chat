RSpec.describe AnswerInsightsJob do
  let(:answer) { create(:answer) }

  before { allow(AnswerInsights::TopicTagger).to receive(:call) }

  describe "#perform" do
    it "calls the AnswerInsights::TopicTagger with the answer" do
      expect(AnswerInsights::TopicTagger).to receive(:call).with(answer)
      described_class.new.perform(answer.id)
    end

    context "when the answer does not exist" do
      it "logs a warning" do
        answer_id = 999
        expect(described_class.logger)
          .to receive(:warn)
          .with("No answer found for #{answer_id}")

        described_class.new.perform(answer_id)
        expect(AnswerInsights::TopicTagger).not_to have_received(:call)
      end
    end
  end
end
