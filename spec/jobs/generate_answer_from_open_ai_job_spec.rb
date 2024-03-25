RSpec.describe GenerateAnswerFromOpenAiJob do
  describe "#perform" do
    let(:question) { create :question }

    it "calls OpenaiRagCompletion.call and saves result" do
      allow(AnswerGeneration::OpenaiRagCompletion)
        .to receive(:call).with(question.conversation)
        .and_return("OpenAI responded with...")
      described_class.new.perform(question.id)
      expect(question.answer.message).to eq("OpenAI responded with...")
    end
  end
end
