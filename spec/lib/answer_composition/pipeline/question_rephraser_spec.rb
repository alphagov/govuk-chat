RSpec.describe AnswerComposition::Pipeline::QuestionRephraser do
  context "when the question is the beginning of the conversation" do
    let(:context) { build(:answer_pipeline_context) }

    it "returns nil" do
      expect(described_class.call(context)).to be_nil
    end
  end

  context "when the question is part of an ongoing chat" do
    let(:conversation) { create :conversation, :with_history }
    let(:question) { conversation.questions.strict_loading(false).last }
    let(:context) { build(:answer_pipeline_context, question:) }

    context "when there is a valid response from OpenAI" do
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
      let(:rephrased) { "How do I pay my corporation tax" }

      before do
        stub_openai_chat_completion(expected_messages, rephrased)
      end

      it "calls openAI with the correct payload and returns the rephrased answer" do
        expect(described_class.call(context)).to eq(rephrased)
      end

      it "updates the contexts question_message with the rephrased question" do
        described_class.call(context)
        expect(context.question_message).to eq(rephrased)
      end
    end

    context "when there is an OpenAIClient::ClientError" do
      let(:context) { build(:answer_pipeline_context, question:) }

      before do
        stub_openai_chat_completion_error
      end

      it "raises a OpenAIClient::RequestError with a modified message" do
        expect { described_class.call(context) }
          .to raise_error(
            an_instance_of(OpenAIClient::RequestError)
            .and(having_attributes(response: an_instance_of(Hash),
                                   message: "could not rephrase #{question.message}",
                                   cause: an_instance_of(OpenAIClient::ClientError))),
          )
      end
    end

    context "when there is an OpenAIClient::ContextLengthExceededError" do
      let(:context) { build(:answer_pipeline_context, question:) }

      before do
        stub_openai_chat_completion_error(code: "context_length_exceeded")
      end

      it "raises a OpenAIClient::ContextLengthExceededError with a modified message" do
        expect { described_class.call(context) }
          .to raise_error(
            an_instance_of(OpenAIClient::ContextLengthExceededError)
              .and(having_attributes(response: an_instance_of(Hash),
                                     message: "Exceeded context length rephrasing #{question.message}",
                                     cause: an_instance_of(OpenAIClient::ContextLengthExceededError))),
          )
      end
    end

    context "with a long history" do
      let(:conversation) { create(:conversation) }
      let(:question) { create(:question, message: "Question 6", conversation:) }
      let(:context) { build(:answer_pipeline_context, question:) }
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
        ]
      end

      before do
        (1..5).each do |n|
          answer = build(:answer, message: "Answer #{n}")
          create(:question, answer:, conversation:, message: "Question #{n}")
        end
      end

      it "truncates the history to the last 5 Q/A pairs" do
        rephrased = "How do I pay my corporation tax"
        stub_openai_chat_completion(expected_messages, rephrased)
        expect(described_class.call(context)).to eq(rephrased)
      end
    end
  end

  def system_prompt
    Rails.configuration.llm_prompts.answer_composition.rephrase_question.system_prompt
  end
end
