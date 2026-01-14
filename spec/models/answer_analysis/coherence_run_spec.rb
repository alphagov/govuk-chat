RSpec.describe AnswerAnalysis::CoherenceRun do
  include_examples "llm calls recordable" do
    let(:model) { build(:coherence_run) }
  end

  include_examples "auto_evaluation create runs from score results", :coherence_runs
  include_examples "auto evaluation exportable runs"
end
