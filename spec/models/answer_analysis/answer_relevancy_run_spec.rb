RSpec.describe AnswerAnalysis::AnswerRelevancyRun do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_relevancy_run) }
  end
end
