RSpec.describe AnswerComposition::QuestionRephraser do
  before do
    allow(Rails.logger).to receive(:error)
  end

  context "when the question is the beginning of the conversation" do
    let(:question) { create :question }

    it "returns the question as-is" do
      expect(described_class.call(question:)).to eq(question.message)
    end
  end

  context "when the conversation hasn't been persisted to the database" do
    let(:question) { build(:question, conversation: build(:conversation)) }

    it "returns the question as-is" do
      expect(described_class.call(question:)).to eq(question.message)
    end
  end

  context "when the question is part of an ongoing chat" do
    let(:conversation) { create :conversation, :with_history }
    let(:question) { conversation.questions.strict_loading(false).last }
    let(:expected_messages) do
      [
        { role: "system", content: system_prompt },
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

      it "raises a OpenAIClient::RequestError with a modified message" do
        expect { described_class.call(question:) }
          .to raise_error(
            an_instance_of(OpenAIClient::RequestError)
            .and(having_attributes(response: an_instance_of(Hash),
                                   message: "could not rephrase #{question.message}",
                                   cause: an_instance_of(OpenAIClient::ClientError))),
          )
      end

      it "Logs the error" do
        expect { described_class.call(question:) }.to raise_error(OpenAIClient::RequestError)
        expect(Rails.logger).to have_received(:error).with("OpenAI error rephrasing question: the server responded with status 400")
      end
    end

    context "when there is an OpenAIClient::ContextLengthExceededError" do
      before do
        stub_openai_chat_completion_error(code: "context_length_exceeded")
      end

      it "raises a OpenAIClient::ContextLengthExceededError with a modified message" do
        expect { described_class.call(question:) }
          .to raise_error(
            an_instance_of(OpenAIClient::ContextLengthExceededError)
              .and(having_attributes(response: an_instance_of(Hash),
                                     message: "Exceeded context length rephrasing #{question.message}",
                                     cause: an_instance_of(OpenAIClient::ContextLengthExceededError))),
          )
      end

      it "Logs the error" do
        expect { described_class.call(question:) }.to raise_error(OpenAIClient::ContextLengthExceededError)
        expect(Rails.logger).to have_received(:error).with("Exceeded context length rephrasing question: the server responded with status 400")
      end
    end

    context "with a long history" do
      let(:expected_messages) do
        [
          { role: "system", content: system_prompt },
          { role: "user", content: "Question 2" },
          { role: "assistant", content: "Answer 2" },
          { role: "user", content: "Question 3" },
          { role: "assistant", content: "Answer 3" },
          { role: "user", content: "Question 4" },
          { role: "assistant", content: "Answer 4" },
          { role: "user", content: "Question 5" },
          { role: "assistant", content: "Answer 5" },
          { role: "user", content: "Question 6" },
          { role: "assistant", content: "Answer 6" },
        ]
      end

      before do
        create :answer, question:, message: "You can pay..."
        (1..6).each do |n|
          answer = build :answer, question:, message: "Answer #{n}"
          create :question, answer:, conversation:, message: "Question #{n}"
        end
      end

      it "truncates the history to the last 5 Q/A pairs" do
        rephrased = "How do I pay my corporation tax"
        stub_openai_chat_completion(expected_messages, rephrased)
        expect(described_class.call(question:)).to eq(rephrased)
      end
    end
  end

  def system_prompt
    Rails.configuration.llm_prompts.answer_composition.rephrase_question.system_prompt
  end
end
