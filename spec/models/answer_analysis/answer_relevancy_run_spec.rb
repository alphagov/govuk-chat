RSpec.describe AnswerAnalysis::AnswerRelevancyRun do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_relevancy_run) }
  end

  include_examples "auto_evaluation create runs from score results", :answer_relevancy_runs
end
