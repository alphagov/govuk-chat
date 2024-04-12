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

    context "when there is an OpenAIClient::ClientError" do
      before do
        stub_openai_chat_completion_error
      end

      it "raises a RephrasingError" do
        expect { described_class.call(question:) }
          .to raise_error(an_instance_of(described_class::RephrasingError)
            .and(having_attributes(
                   response: an_instance_of(Hash),
                   message: "could not rephrase #{question.message}",
                   cause: an_instance_of(OpenAIClient::ClientError),
                 )))
      end
    end

    context "when there is an OpenAIClient::ContextLengthExceededError" do
      before do
        stub_openai_chat_completion_error(code: "context_length_exceeded")
      end

      it "raises a RephrasingError" do
        expect { described_class.call(question:) }
          .to raise_error(an_instance_of(described_class::RephrasingError)
            .and(having_attributes(
                   response: an_instance_of(Hash),
                   message: "Exceeded context length rephrasing #{question.message}",
                   cause: an_instance_of(OpenAIClient::ContextLengthExceededError),
                 )))
      end
    end

    context "with a long history" do
      let(:expected_messages) do
        [
          { role: "system", content: AnswerComposition::Prompts::QUESTION_REPHRASER },
          { role: "user", content: "What types are there" },
          { role: "assistant", content: "Self-assessment, PAYE, Corporation tax" },
          { role: "user", content: "corporation tax" },
          { role: "assistant", content: "You can pay..." },
          { role: "user", content: "Question 1" },
          { role: "assistant", content: "Answer 1" },
          { role: "user", content: "Question 2" },
          { role: "assistant", content: "Answer 2" },
          { role: "user", content: "Question 3" },
          { role: "assistant", content: "Answer 3" },
        ]
      end

      before do
        create :answer, question: conversation.questions.last, message: "You can pay..."
        (1..3).each do |n|
          question = create :question, conversation:, message: "Question #{n}"
          create :answer, question:, message: "Answer #{n}"
        end
      end

      it "truncates the history to the last 5 Q/A pairs" do
        rephrased = "How do I pay my corporation tax"
        stub_openai_chat_completion(expected_messages, rephrased)
        expect(described_class.call(question:)).to eq(rephrased)
      end
    end
  end
end
