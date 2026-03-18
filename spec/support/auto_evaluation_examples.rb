shared_examples "auto evaluation exportable runs" do
  let(:run_factory_name) { described_class.name.demodulize.underscore }

  describe "#serialize_for_export" do
    it "returns a serialized object for export" do
      record = build(
        run_factory_name,
        llm_responses: {
          "verdicts" => { "verdicts" => [{ "verdict" => "yes" }] },
          "reason" => { "reason" => "This is the reason for the score." },
        },
      )

      expected = record.as_json.merge(
        "llm_responses" => record.llm_responses.to_json,
      )
      expect(record.serialize_for_export).to eq(expected)
    end
  end

  it_behaves_like "exportable by start and end date" do
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, conversation:) }
    let(:answer) { create(:answer, question:) }
    let(:create_record_lambda) { ->(time) { create(run_factory_name, created_at: time) } }
  end
end

shared_examples "auto_evaluation create runs from auto evaluation results" do |run_association|
  describe ".create_runs_from_auto_evaluation_results" do
    let(:success_run_result) { build(:auto_evaluation_result, score: 0.9) }
    let(:failure_run_result) { build(:auto_evaluation_result, score: 0.3, status: "failure") }
    let(:error_run_result) { build(:auto_evaluation_result, :with_error) }

    let(:results) { [success_run_result, failure_run_result, error_run_result] }
    let(:answer) { create(:answer) }
    let(:answer_id) { answer.id }

    it "creates runs within a transaction with correct attributes and associations" do
      answer = Answer.includes(run_association).find(answer_id)
      expect(described_class).to receive(:transaction).and_call_original

      expect {
        described_class.create_runs_from_auto_evaluation_results(answer, results, run_association)
      }.to change(answer.public_send(run_association), :count).by(3)

      first_run, second_run, third_run = answer.reload.public_send(run_association)

      expect(first_run).to have_attributes(success_run_result.to_h)
      expect(second_run).to have_attributes(failure_run_result.to_h)
      expect(third_run).to have_attributes(error_run_result.to_h)
    end
  end
end

shared_examples "an auto evaluation class that rescues BedrockOpenAIOssInvoke::InvalidToolCallError" do |expected_llm_and_metric_keys = nil|
  context "when a BedrockOpenAIOssInvoke::InvalidToolCallError is raised" do
    let(:error_message) { "Some error message" }

    it "returns a result object with the expected attributes" do
      allow(AutoEvaluation::BedrockOpenAIOssInvoke).to receive(:call)
                                           .and_raise(
                                             AutoEvaluation::BedrockOpenAIOssInvoke::InvalidToolCallError.new(error_message),
                                           )

      result = described_class.call(answer)

      expect(result)
        .to be_a(AutoEvaluation::Result)
        .and have_attributes(
          status: "error",
          score: nil,
          reason: nil,
          error_message: error_message,
          llm_responses: {},
          metrics: {},
        )
    end

    if expected_llm_and_metric_keys.present?
      it "retains the llm_responses and metrics from any successful calls before the error is raised" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0, 204.0, 206.0)
        allow(described_class::ReasonGenerator).to receive(:call)
                                              .and_raise(
                                                AutoEvaluation::BedrockOpenAIOssInvoke::InvalidToolCallError.new(
                                                  error_message,
                                                ),
                                              )

        result = described_class.call(answer)

        expect(result.llm_responses.keys).to eq(expected_llm_and_metric_keys)
        expect(result.metrics.keys).to eq(expected_llm_and_metric_keys)
      end
    end
  end
end
