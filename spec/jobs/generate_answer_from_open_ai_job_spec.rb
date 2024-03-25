RSpec.describe GenerateAnswerFromOpenAiJob do
  describe "#perform" do
    let(:question) { create :question }
    let(:returned_answer) { build(:answer, question:, message: "OpenAI responded with...") }

    it "calls OpenaiRagCompletion.call and saves the resulting answer" do
      allow(AnswerGeneration::OpenaiRagCompletion)
        .to receive(:call).with(question)
        .and_return(returned_answer)
      expect { described_class.new.perform(question.id) }.to change(Answer, :count).by(1)
      expect(question.answer).to eq(returned_answer)
    end
  end
end
