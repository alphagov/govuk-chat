RSpec.describe AnswerTopicsJob do
  include ActiveJob::TestHelper
  let(:answer) { create(:answer) }

  before { allow(AnswerAnalysisGeneration::TopicTagger).to receive(:call) }

  describe "#perform" do
    it "calls the AnswerAnalysisGeneration::TopicTagger with the answer" do
      described_class.new.perform(answer.id)
      expect(AnswerAnalysisGeneration::TopicTagger).to have_received(:call).with(answer)
    end

    context "when the answer does not exist" do
      let(:answer_id) { 999 }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("No answer found for #{answer_id}")

        described_class.new.perform(answer_id)
      end

      it "doesn't call the TopicTagger" do
        described_class.new.perform(answer_id)
        expect(AnswerAnalysisGeneration::TopicTagger).not_to have_received(:call)
      end
    end

    context "when the answer analysis has tagged topics" do
      let(:answer) { create(:answer, :with_analysis) }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Answer #{answer.id} has already been tagged with topics")

        described_class.new.perform(answer.id)
      end
    end

    context "when TopicTagger raises an Anthropic::Errors::APIError" do
      it "retries the job the max number of times" do
        allow(AnswerAnalysisGeneration::TopicTagger).to receive(:call)
          .and_raise(Anthropic::Errors::APIError.new(
                       url: "url",
                     ))

        (described_class::MAX_RETRIES - 1).times do
          described_class.perform_later(answer.id)
          expect { perform_enqueued_jobs }.not_to raise_error
        end

        described_class.perform_later(answer.id)
        expect { perform_enqueued_jobs }.to raise_error(Anthropic::Errors::APIError)
      end
    end
  end
end
