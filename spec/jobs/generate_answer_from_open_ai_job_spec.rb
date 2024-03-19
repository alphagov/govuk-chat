RSpec.describe GenerateAnswerFromOpenAiJob do
  around do |example|
    ClimateControl.modify(
      OPENAI_MODEL: "gpt-3.5-turbo",
      OPENAI_ACCESS_TOKEN: "open-ai-token",
    ) do
      example.run
    end
  end

  describe "#perform" do
    let(:question) { create :question }

    before do
      stub_openai_chat_response(question.message, "OpenAI responded with...")
    end

    it "calls OpenAI chat endpoint and saves result" do
      expect { described_class.new.perform(question.id) }.to change(Answer, :count).by(1)
      expect(question.answer.message).to eq("OpenAI responded with...")
    end
  end
end
