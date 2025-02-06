RSpec.describe AnswerComposition::Pipeline::Claude::QuestionRephraser do
  let(:conversation) { create :conversation, :with_history }
  let(:question) { conversation.questions.strict_loading(false).last }
  let(:context) { build(:answer_pipeline_context, question:) }
  let(:question_records) { conversation.questions.joins(:answer) }

  context "when there is a valid response from Claude" do
    let(:expected_user_prompt) do
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

      config[:user_prompt]
        .sub("{message_history}", message_history)
        .sub("{question}", "corporation tax")
    end
    let(:rephrased) { "How do I pay my corporation tax" }

    before do
      stub_bedrock_converse(
        bedrock_claude_text_response(rephrased, user_message: expected_user_prompt),
      )
    end

    it "returns a result object" do
      result = described_class.call(question.message, question_records)

      llm_response = result.llm_response
      expect(llm_response[:stop_reason]).to eq("end_turn")
      expect(llm_response.dig(:output, :message, :content, 0, :text)).to eq(rephrased)

      expect(result.rephrased_question).to eq(rephrased)
      expect(result.metrics).to eq({
        llm_prompt_tokens: 10,
        llm_completion_tokens: 20,
      })
    end
  end

  context "when a question has been rephrased" do
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, conversation:) }
    let(:context) { build(:answer_pipeline_context, question:) }
    let(:answer) { build(:answer, rephrased_question: "A rephrased question") }

    before { create(:question, conversation:, answer:) }

    it "includes the rephrased question in the history" do # rubocop:disable RSpec/NoExpectationExample
      message_history = <<~HISTORY.strip
        user:
        """
        A rephrased question
        """
        assistant:
        """
        #{answer.message}
        """
      HISTORY

      expected_user_prompt = config[:user_prompt]
        .sub("{message_history}", message_history)
        .sub("{question}", question.message)

      stub_bedrock_converse(
        bedrock_claude_text_response("A second rephrased question", user_message: expected_user_prompt),
      )

      described_class.call(question.message, conversation.questions.joins(:answer))
    end
  end
end

def config
  Rails.configuration.govuk_chat_private.llm_prompts.claude.question_rephraser
end
