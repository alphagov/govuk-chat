RSpec.describe AnswerAnalysis do
  describe ".enqueue_async_analysis" do
    it "enqueues the analysis jobs" do
      answer = build(:answer)
      expect(described_class::TagTopicsJob).to receive(:perform_later).with(answer.id)
      expect(described_class::AnswerRelevancyJob).to receive(:perform_later).with(answer.id)
      expect(described_class::CoherenceJob).to receive(:perform_later).with(answer.id)
      expect(described_class::FaithfulnessJob).to receive(:perform_later).with(answer.id)
      described_class.enqueue_async_analysis(answer)
    end
  end
end
