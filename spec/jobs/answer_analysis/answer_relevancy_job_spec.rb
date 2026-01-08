RSpec.describe AnswerAnalysis::AnswerRelevancyJob do
  include ActiveJob::TestHelper

  let(:answer) { create(:answer) }
  let(:question) { answer.question }
  let(:results) do
    [
      build(:auto_evaluation_score_result, score: 0.8),
      build(:auto_evaluation_score_result, score: 0.7),
      build(:auto_evaluation_score_result, score: 0.9),
    ]
  end

  before do
    allow(AutoEvaluation::AnswerRelevancy)
      .to receive(:call).and_return(*results)
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it_behaves_like "a job in queue", "default"
  it_behaves_like "a job that adheres to the auto_evaluation quota", AutoEvaluation::AnswerRelevancy
  it_behaves_like "a job that retries on errors", Aws::Errors::ServiceError do
    before do
      allow(AutoEvaluation::AnswerRelevancy)
        .to receive(:call)
        .and_raise(Aws::Errors::ServiceError.new(nil, "error"))
    end
  end

  describe "#perform" do
    let(:answer_id) { answer.id }

    it "calls AutoEvaluation::AnswerRelevancy the configured number of times with the correct arguments" do
      described_class.new.perform(answer_id)

      expect(AutoEvaluation::AnswerRelevancy)
        .to have_received(:call)
        .with(answer)
        .exactly(AnswerAnalysis::BaseJob::NUMBER_OF_RUNS).times
    end

    it "creates answer relevancy runs for each result" do
      expect {
        described_class.new.perform(answer_id)
      }.to change(AnswerAnalysis::AnswerRelevancyRun, :count).by(results.count)

      answer = Answer.includes(:answer_relevancy_runs)
                     .find(answer_id)

      results.each_with_index do |result, index|
        expect(answer.answer_relevancy_runs[index])
          .to have_attributes(result.to_h.except(:success))
      end
    end

    context "when the answer has a rephrased_question" do
      let(:rephrased_question) { "This is a rephrased_question" }

      it "passes the rephrased question to AutoEvaluation::AnswerRelevancy as the question_message" do
        answer = create(:answer, rephrased_question: rephrased_question)

        described_class.new.perform(answer.id)

        expect(AutoEvaluation::AnswerRelevancy)
          .to have_received(:call)
          .with(answer)
          .exactly(AnswerAnalysis::BaseJob::NUMBER_OF_RUNS).times
      end
    end

    context "when the answer does not exist" do
      let(:answer_id) { 999 }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Couldn't find an answer 999 that was eligible for auto-evaluation")

        described_class.new.perform(answer_id)
      end

      it "doesn't call AutoEvaluation::AnswerRelevancy" do
        described_class.new.perform(answer_id)
        expect(AutoEvaluation::AnswerRelevancy).not_to have_received(:call)
      end
    end

    context "when answer relevancy has already been evaluated" do
      let(:run) { create(:answer_relevancy_run) }
      let(:answer) { run.answer }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Answer #{answer.id} has already been evaluated for relevancy")

        described_class.new.perform(answer.id)
      end

      it "doesn't call AutoEvaluation::AnswerRelevancy" do
        described_class.new.perform(answer.id)
        expect(AutoEvaluation::AnswerRelevancy).not_to have_received(:call)
      end
    end

    context "when the answer is not eligible for auto-evaluation" do
      let(:answer) { create(:answer, status: Answer.statuses.except(:answered).keys.sample) }

      it "logs a warning message" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Couldn't find an answer #{answer.id} that was eligible for auto-evaluation")

        described_class.new.perform(answer.id)
      end

      it "does not call AutoEvaluation::AnswerRelevancy" do
        expect(AutoEvaluation::AnswerRelevancy).not_to receive(:call)
        described_class.new.perform(answer.id)
      end
    end
  end
end
