RSpec.describe AutoEvaluation::RunMetricEvaluation, :aws_credentials_stubbed do
  let(:answer) { build(:answer) }
  let(:question_message) { "What is the capital of France?" }
  let(:evaluation_result) { build(:auto_evaluation_score_result) }

  before do
    allow(AnswerComposition::PipelineRunner)
      .to receive(:call)
      .with(
        question: an_instance_of(Question),
        pipeline: [
          AnswerComposition::Pipeline::SearchResultFetcher,
          AnswerComposition::Pipeline::Claude::StructuredAnswerComposer,
        ],
      )
      .and_return(answer)
  end

  [
    AutoEvaluation::AnswerRelevancy,
    AutoEvaluation::Coherence,
  ].each do |metric_class|
    context "when passed the #{metric_class} metric class" do
      before do
        allow(metric_class)
          .to receive(:call)
          .and_return(evaluation_result)
      end

      it "calls #{metric_class} with the correct parameters" do
        described_class.call(
          metric_class: metric_class,
          question_message:,
        )

        expect(metric_class).to have_received(:call).with(
          question_message:,
          answer_message: answer.message,
        )
      end

      it "returns the metrics ScoreResult" do
        result = described_class.call(
          metric_class: metric_class,
          question_message:,
        )
        expect(result).to eq(evaluation_result)
      end
    end
  end

  context "when the generated answer has an error status" do
    let(:answer) { build(:answer, status: :error_answer_service_error, error_message: "Contrived error.") }

    it "returns the answer" do
      result = described_class.call(
        metric_class: AutoEvaluation::Coherence,
        question_message:,
      )
      expect(result).to eq(answer)
    end
  end
end
