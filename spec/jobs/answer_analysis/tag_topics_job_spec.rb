RSpec.describe AnswerAnalysis::TagTopicsJob do
  include ActiveJob::TestHelper
  let(:answer) { create(:answer) }
  let(:question) { answer.question }
  let(:topic_tagger_result) do
    AutoEvaluation::TopicTagger::Result.new(
      status: status,
      primary_topic: "business",
      secondary_topic: "benefits",
      metrics: {
        "duration" => 1.5,
        "model" => "some-model",
      },
      llm_response: {
        "model" => "some-model",
      },
      error_message:,
    )
  end
  let(:status) { "success" }
  let(:error_message) { nil }

  before do
    allow(AutoEvaluation::TopicTagger).to receive(:call).and_return(topic_tagger_result)
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it_behaves_like "a job in queue", "default"
  it_behaves_like "a job that adheres to the auto_evaluation quota", AutoEvaluation::TopicTagger
  it_behaves_like "a job that retries on aws sdk errors", AutoEvaluation::TopicTagger

  describe "#perform" do
    it "calls the AutoEvaluation::TopicTagger with the answer message" do
      described_class.new.perform(answer.id)
      expect(AutoEvaluation::TopicTagger).to have_received(:call).with(question.message)
    end

    it "creates topics for the answer based of the returned result" do
      expect {
        described_class.new.perform(answer.id)
      }.to change(AnswerAnalysis::Topics, :count).by(1)
      expect(answer.reload.topics)
        .to have_attributes(
          status: topic_tagger_result.status,
          primary_topic: topic_tagger_result.primary_topic,
          secondary_topic: topic_tagger_result.secondary_topic,
          metrics: { "topic_tagger" => topic_tagger_result.metrics },
          llm_responses: { "topic_tagger" => topic_tagger_result.llm_response },
          error_message: nil,
        )
    end

    context "when the AutoEvaluation::TopicTagger returns an error status and error message" do
      let(:status) { "error" }
      let(:error_message) { "An error occurred during topic tagging" }

      it "creates topics with the error status and error message" do
        described_class.new.perform(answer.id)
        expect(answer.reload.topics)
          .to have_attributes(
            status: status,
            error_message: error_message,
          )
      end
    end

    context "when the answer does not exist" do
      let(:answer_id) { 999 }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("No answer found for #{answer_id}")

        described_class.new.perform(answer_id)
      end

      it "doesn't call the AutoEvaluation::TopicTagger" do
        described_class.new.perform(answer_id)
        expect(AutoEvaluation::TopicTagger).not_to have_received(:call)
      end
    end

    context "when topics have been tagged" do
      let(:answer) { create(:answer, :with_topics) }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Answer #{answer.id} has already been tagged with topics")

        described_class.new.perform(answer.id)
      end
    end

    context "when the answer is not eligible for topic analysis" do
      let(:answer) { create(:answer, status: Answer::STATUSES_EXCLUDED_FROM_TOPIC_ANALYSIS.sample) }

      it "logs an info message" do
        expect(described_class.logger)
          .to receive(:info)
          .with("Answer #{answer.id} is not eligible for topic analysis")

        described_class.new.perform(answer.id)
      end

      it "does not call the AutoEvaluation::TopicTagger" do
        expect(AutoEvaluation::TopicTagger).not_to receive(:call)
        described_class.new.perform(answer.id)
      end
    end
  end
end
