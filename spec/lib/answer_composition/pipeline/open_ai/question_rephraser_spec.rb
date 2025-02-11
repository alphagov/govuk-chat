RSpec.describe AnswerComposition::Pipeline::OpenAI::QuestionRephraser do
  let(:conversation) { create :conversation, :with_history }
  let(:question) { conversation.questions.strict_loading(false).last }
  let(:question_records) { conversation.questions.joins(:answer) }

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
      stub_openai_chat_completion(expected_messages, answer: rephrased)
    end

    it "returns a result object" do
      result = described_class.call(question.message, question_records)

      expect(result.llm_response).to match(
        a_hash_including(
          "finish_reason" => "stop",
          "message" => a_hash_including({ "content" => rephrased }),
        ),
      )

      expect(result.rephrased_question).to eq(rephrased)

      expect(result.metrics).to eq({
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
        llm_cached_tokens: 10,
      })
    end
  end

  context "when a question has been rephrased" do
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, conversation:) }
    let(:answer) { build(:answer, rephrased_question: "A rephrased question") }

    before { create(:question, conversation:, answer:) }

    it "includes the rephrased question in the history" do
      request = stub_openai_question_rephrasing(answer.rephrased_question, "Answer from OpenAI")
      described_class.call(question.message, conversation.questions.joins(:answer))
      expect(request).to have_been_made
    end
  end
end

def config
  Rails.configuration.govuk_chat_private.llm_prompts.openai.question_rephraser
end
