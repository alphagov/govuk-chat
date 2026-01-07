RSpec.describe AnswerAnalysis::TagTopicsJob do
  include ActiveJob::TestHelper
  let(:answer) { create(:answer) }
  let(:question) { answer.question }
  let(:topic_tagger_result) do
    AutoEvaluation::TopicTagger::Result.new(
      primary_topic: "business",
      secondary_topic: "benefits",
      metrics: {
        "duration" => 1.5,
        "model" => "some-model",
      },
      llm_response: {
        "model" => "some-model",
      },
    )
  end

  before { allow(AutoEvaluation::TopicTagger).to receive(:call).and_return(topic_tagger_result) }

  it_behaves_like "a job in queue", "default"

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
          primary_topic: topic_tagger_result.primary_topic,
          secondary_topic: topic_tagger_result.secondary_topic,
          metrics: { "topic_tagger" => topic_tagger_result.metrics },
          llm_responses: { "topic_tagger" => topic_tagger_result.llm_response },
        )
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

    context "when AutoEvaluation::TopicTagger raises an Anthropic::Errors::APIError" do
      it "retries the job the max number of times" do
        allow(AutoEvaluation::TopicTagger).to receive(:call)
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
