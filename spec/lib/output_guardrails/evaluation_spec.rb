require "csv"

RSpec.describe OutputGuardrails::Evaluation do
  let(:file_path) { Rails.root.join("spec/support/files/output_guardrails_fewshot_examples.csv") }

  context "when Evaluating FewShot" do
    describe "#call" do
      it "evaluates the examples correctly" do
        result = described_class.call(file_path) { |_input| 'True | "1"' }
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
