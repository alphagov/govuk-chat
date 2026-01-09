RSpec.describe AnswerAnalysis::ContextRelevancyRun do
  include_examples "llm calls recordable" do
    let(:model) { build(:context_relevancy_run) }
  end

  include_examples "auto_evaluation create runs from score results", :context_relevancy_runs
end
