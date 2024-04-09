RSpec.describe AnswerComposition::QuestionRephraser do
  context "when the question is the beginning of the conversation" do
    let(:question) { create :question }

    it "returns the question as-is" do
      expect(described_class.call(question:)).to eq(question.message)
    end
  end

  context "when the question is part of an ongoing chat" do
    let(:conversation) { create :conversation, :with_history }
    let(:question) { conversation.questions.last }
    let(:expected_messages) do
      [
        { role: "system", content: AnswerComposition::Prompts::QUESTION_REPHRASER },
        { role: "user", content: "How do I pay my tax" },
        { role: "assistant", content:  "What type of tax" },
        { role: "user", content: "What types are there" },
        { role: "assistant", content: "Self-assessment, PAYE, Corporation tax" },
        { role: "user", content: "corporation tax" },
      ]
    end

    it "calls openAI with the correct payload and returns the rephrased answer" do
      rephrased = "How do I pay my corporation tax"
      stub_openai_chat_completion(expected_messages, rephrased)
      expect(described_class.call(question:)).to eq(rephrased)
    end
  end
end
