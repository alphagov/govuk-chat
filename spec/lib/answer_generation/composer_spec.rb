RSpec.describe AnswerGeneration::Composer do
  let(:question) { create :question }
  let(:retrieved_answer) { build :answer, question: }

  describe ".call" do
    context "when the question is for open ai" do
      let(:question) { create :question, answer_strategy: :open_ai_rag_completion }

      it "get the result via OpenAiRagCompletion.call(question)" do
        allow(AnswerGeneration::OpenaiRagCompletion)
          .to receive(:call).with(question).and_return(retrieved_answer)
        expect(described_class.call(question)).to eq(retrieved_answer)

        expect(AnswerGeneration::OpenaiRagCompletion).to have_received(:call).with(question)
      end
    end

    context "when the question is for chat API" do
      let(:question) { create :question, answer_strategy: :govuk_chat_api }

      it "get the result via ChatApiCompletion.call(question)" do
        allow(AnswerGeneration::GovukChatApi)
          .to receive(:call).with(question).and_return(retrieved_answer)
        expect(described_class.call(question)).to eq(retrieved_answer)

        expect(AnswerGeneration::GovukChatApi).to have_received(:call).with(question)
      end
    end

    context "when the question is for an unknown strategy" do
      let(:question) { build_stubbed(:question) }

      it "raises an error" do
        allow(question).to receive(:answer_strategy).and_return("unknown")

        expect { described_class.call(question) }
          .to raise_error("Answer strategy unknown not configured")
      end
    end
  end
end
