RSpec.describe AnswerAnalysis do
  include_examples "llm calls recordable" do
    let(:model) { build(:answer_analysis) }
  end
end
