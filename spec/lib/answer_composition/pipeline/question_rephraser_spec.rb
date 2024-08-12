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
        message_history = <<~HISTORY.strip
          user:
          """
          How do I pay my tax
          """
          assistant:
          """
          What type of tax
          """
          user:
          """
          What types are there
          """
          assistant:
          """
          Self-assessment, PAYE, Corporation tax
          """
        HISTORY

        user_prompt = config[:user_prompt]
                      .sub("{message_history}", message_history)
                      .sub("{question}", "corporation tax")

        [
          { role: "system", content: config[:system_prompt] },
          { role: "user", content: user_prompt },
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

    context "when a question has been rephrased" do
      let(:conversation) { create(:conversation) }
      let(:question) { create(:question, conversation:) }
      let(:context) { build(:answer_pipeline_context, question:) }

      before do
        answer = build(:answer, rephrased_question: "A rephrased question")
        create(:question, conversation:, answer:)
      end

      it "includes the rephrased question in the history" do
        stub_openai_chat_completion(
          array_including({ "role" => "user", "content" => a_string_including("A rephrased question") }),
          "Answer from OpenAI",
        )

        expect(described_class.call(context)).to eq("Answer from OpenAI")
      end
    end

    context "with a long history" do
      let(:conversation) { create(:conversation) }
      let(:question) { create(:question, message: "Question 7", conversation:) }
      let(:context) { build(:answer_pipeline_context, question:) }
      let(:user_prompt) do
        message_history = (2..6).map do |n|
          <<~MESSAGE.strip
            user:
            """
            Question #{n}
            """
            assistant:
            """
            Answer #{n}
            """
          MESSAGE
        end

        config[:user_prompt]
          .sub("{message_history}", message_history.join("\n"))
          .sub("{question}", "Question 7")
      end
      let(:expected_messages) do
        [
          { role: "system", content: config[:system_prompt] },
          { role: "user", content: user_prompt },
        ]
      end

      before do
        (1..6).each do |n|
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

  def config
    Rails.configuration.llm_prompts.question_rephraser
  end
end
