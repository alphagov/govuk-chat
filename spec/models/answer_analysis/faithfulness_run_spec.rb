RSpec.describe AnswerAnalysis::FaithfulnessRun do
  include_examples "llm calls recordable" do
    let(:model) { build(:faithfulness_run) }
  end

  include_examples "auto_evaluation create runs from score results", :faithfulness_runs
  include_examples "auto evaluation exportable runs"
end
