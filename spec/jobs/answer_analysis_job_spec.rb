RSpec.describe AnswerAnalysisJob do
  let(:answer) { build :answer }

  before do
    allow(AnswerAnalysis::TagTopicsJob).to receive(:perform_later)
    allow(AnswerAnalysis::AnswerRelevancyJob).to receive(:perform_later)
  end

  it "calls the AnswerAnalysis::TagTopicsJob with the answer id" do
    described_class.new.perform(answer.id)
    expect(AnswerAnalysis::TagTopicsJob).to have_received(:perform_later).with(answer.id)
  end

  it "calls the AnswerAnalysis::AnswerRelevancyJob with the answer id" do
    described_class.new.perform(answer.id)
    expect(AnswerAnalysis::AnswerRelevancyJob).to have_received(:perform_later).with(answer.id)
  end
end
