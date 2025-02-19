RSpec.describe AnswerComposition::Pipeline::Claude::QuestionRephraser do
  let(:conversation) { create :conversation, :with_history }
  let(:question) { conversation.questions.strict_loading(false).last }
  let(:context) { build(:answer_pipeline_context, question:) }
  let(:question_records) { conversation.questions.joins(:answer) }

  context "when there is a valid response from Claude" do
    let(:rephrased) { "How do I pay my corporation tax" }

    it "includes the current question in the user prompt" do
      client = stub_bedrock_converse(
        bedrock_claude_text_response(rephrased, user_message: Regexp.new(question.message)),
      )
      described_class.call(question.message, question_records)

      expect(client.api_requests.size).to eq(1)
    end

    it "includes the message_history in the user prompt" do
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

      client = stub_bedrock_converse(
        bedrock_claude_text_response(rephrased, user_message: Regexp.new(message_history)),
      )
      described_class.call(question.message, question_records)

      expect(client.api_requests.size).to eq(1)
    end

    it "returns a result object" do
      stub_bedrock_converse(bedrock_claude_text_response(rephrased))
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

    it "includes the rephrased question in the history" do
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

      client = stub_bedrock_converse(
        bedrock_claude_text_response(
          "A second rephrased question", user_message: Regexp.new(message_history)
        ),
      )

      described_class.call(question.message, conversation.questions.joins(:answer))

      expect(client.api_requests.size).to eq(1)
    end
  end
end
