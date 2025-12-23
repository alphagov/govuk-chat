RSpec.describe AnswerAnalysis::AnswerRelevancyJob do
  include ActiveJob::TestHelper

  let(:answer) { create(:answer) }
  let(:question) { answer.question }
  let(:first_result) do
    AutoEvaluation::AnswerRelevancy::Result.new(
      score: 0.8,
      reason: "The first reason.",
      success: true,
      llm_responses: {
        "response_1" => { "content" => "LLM response content 1" },
        "response_2" => { "content" => "LLM response content 2" },
      },
      metrics: {
        "metric_1" => { "detail" => "Metric detail 1" },
        "metric_2" => { "detail" => "Metric detail 2" },
      },
    )
  end
  let(:second_result) do
    AutoEvaluation::AnswerRelevancy::Result.new(
      score: 0.7,
      reason: "The second reason.",
      success: true,
      llm_responses: {
        "response_3" => { "content" => "LLM response content 3" },
        "response_4" => { "content" => "LLM response content 4" },
      },
      metrics: {
        "metric_3" => { "detail" => "Metric detail 3" },
        "metric_4" => { "detail" => "Metric detail 4" },
      },
    )
  end
  let(:third_result) do
    AutoEvaluation::AnswerRelevancy::Result.new(
      score: 0.9,
      reason: "The third reason.",
      success: true,
      llm_responses: {
        "response_5" => { "content" => "LLM response content 5" },
        "response_6" => { "content" => "LLM response content 6" },
      },
      metrics: {
        "metric_5" => { "detail" => "Metric detail 5" },
        "metric_6" => { "detail" => "Metric detail 6" },
      },
    )
  end

  before do
    allow(AutoEvaluation::AnswerRelevancy)
      .to receive(:call).and_return(first_result, second_result, third_result)
    stub_const("AnswerAnalysis::BaseMetricJob::NUMBER_OF_RUNS", 3)
  end

  it_behaves_like "a job in queue", "default"

  describe "#perform" do
    it "calls AutoEvaluation::AnswerRelevancy the configured number of times with the correct arguments" do
      described_class.new.perform(answer.id)

      expect(AutoEvaluation::AnswerRelevancy)
        .to have_received(:call)
        .with(
          question_message: question.message,
          answer_message: answer.message,
        )
        .exactly(3).times
    end

    it "creates answer relevancy aggregate with the correct score" do
      expect {
        described_class.new.perform(answer.id)
      }.to change(AnswerAnalysis::AnswerRelevancyAggregate, :count).by(1)
      answer = Answer.includes(:answer_relevancy_aggregate)
                     .find(AnswerAnalysis::AnswerRelevancyAggregate.last.answer_id)
      expect(answer.answer_relevancy_aggregate.mean_score.round(2)).to eq(0.8)
    end

    it "creates answer relevancy runs for each result" do
      expect {
        described_class.new.perform(answer.id)
      }.to change(AnswerAnalysis::AnswerRelevancyRun, :count).by(3)

      answer = Answer.includes(answer_relevancy_aggregate: :runs)
                     .find(AnswerAnalysis::AnswerRelevancyAggregate.last.answer_id)

      [first_result, second_result, third_result].each_with_index do |result, index|
        expect(answer.answer_relevancy_aggregate.runs.sort_by(&:created_at)[index])
          .to have_attributes(
            score: result.score.round(2),
            reason: result.reason,
            llm_responses: result.llm_responses,
            metrics: result.metrics,
          )
      end
    end

    context "when the answer has a rephrased_question" do
      let(:rephrased_question) { "This is a rephrased_question" }

      it "passes the rephrased question to AutoEvaluation::AnswerRelevancy as the question_message" do
        answer = create(:answer, rephrased_question: rephrased_question)

        described_class.new.perform(answer.id)

        expect(AutoEvaluation::AnswerRelevancy)
          .to have_received(:call)
          .with(
            question_message: rephrased_question,
            answer_message: answer.message,
          )
          .exactly(3).times
      end
    end

    context "when aggegate data is persisted mid job" do
      before do
        allow(AnswerAnalysis::AnswerRelevancyAggregate)
          .to receive(:create_mean_aggregate_and_score_runs)
          .with(answer, anything)
          .and_raise(ActiveRecord::RecordNotUnique)
      end

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Answer #{answer.id} has already been evaluated for relevancy")

        described_class.new.perform(answer.id)
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
      let(:aggregate) { create(:answer_relevancy_aggregate) }
      let(:answer) { aggregate.answer }

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

    context "when the AnswerRelevancy metric raises an Aws::Errors::ServiceError" do
      it "retries the job the max number of times" do
        allow(AutoEvaluation::AnswerRelevancy).to receive(:call)
          .and_raise(Aws::Errors::ServiceError.new(nil, "error"))

        (described_class::MAX_RETRIES - 1).times do
          described_class.perform_later(answer.id)
          expect { perform_enqueued_jobs }.not_to raise_error
        end

        described_class.perform_later(answer.id)
        expect { perform_enqueued_jobs }.to raise_error(Aws::Errors::ServiceError)
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
