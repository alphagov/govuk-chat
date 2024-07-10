require "csv"

RSpec.describe OutputGuardrails::Evaluation do
  let(:file_path) { Rails.root.join("spec/support/files/guardrail_exact_examples.csv") }

  context "when Evaluating FewShot" do
    before do
      allow(OutputGuardrails::FewShot).to receive(:call).and_return('True | "1"')
    end

    describe "#call" do
      it "evaluates the examples correctly" do
        result = described_class.call(file_path) { |input| OutputGuardrails::FewShot.call(input) }
        expect(result).to include(
          count: 2,
          percent_correct: 50.0,
          exact_match_count: 1,
          failure_count: 1,
          average_latency: a_value > 0, # some positive latency value
          max_latency: a_value > 0, # some positive latency value
          failures: [{ input: "input2", expected: "False | None", actual: 'True | "1"' }],
        )
      end
    end
  end
end
