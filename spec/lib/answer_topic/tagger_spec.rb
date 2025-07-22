RSpec.describe AnswerTopic::Tagger do
  describe ".call" do
    context "when the answer strategy is :claude_structured_answer" do
      let(:answer) { create(:answer, question: create(:question, answer_strategy: :claude_structured_answer)) }

      it "calls the Claude tagger" do
        expect(AnswerTopic::Claude::Tagger).to receive(:call).with(answer)
        described_class.call(answer)
      end
    end

    context "when the answer strategy is :openai_structured_answer" do
      let(:answer) { create(:answer, question: create(:question, answer_strategy: :openai_structured_answer)) }

      it "raises an error" do
        expect { described_class.call(answer) }
          .to raise_error(RuntimeError, "Invalid strategy: openai_structured_answer")
      end
    end

    context "with any other answer strategy" do
      let(:answer) { create(:answer, question: create(:question, answer_strategy: :open_ai_rag_completion)) }

      it "raises an error" do
        expect { described_class.call(answer) }
          .to raise_error(RuntimeError, "Invalid strategy: open_ai_rag_completion")
      end
    end
  end
end
