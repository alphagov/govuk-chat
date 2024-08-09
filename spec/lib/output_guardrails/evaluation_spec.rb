require "csv"

RSpec.describe OutputGuardrails::Evaluation do
  let(:file_path) { Rails.root.join("spec/support/files/output_guardrails_fewshot_examples.csv") }

  context "when Evaluating FewShot" do
    describe "#call" do
      it "evaluates the examples correctly" do
        result = described_class.call(file_path, true_eval: ->(v) { v != "False | None" }) do |input|
          if ["true positive", "false positive 2", "false positive"].include?(input)
            'True | "1"'
          else
            "False | None"
          end
        end
        expect(result).to include(
          count: 6,
          percent_correct: 50.0,
          exact_match_count: 3,
          precision: 0.33,
          recall: 0.5,
          failure_count: 3,
          average_latency: a_value > 0, # some positive latency value
          max_latency: a_value > 0, # some positive latency value
          failures: [
            { input: "false positive", expected: "False | None", actual: 'True | "1"' },
            { input: "false negative", expected: 'True | "1"', actual: "False | None" },
            { input: "false positive 2", expected: "False | None", actual: 'True | "1"' },
          ],
        )
      end
    end
  end
end
