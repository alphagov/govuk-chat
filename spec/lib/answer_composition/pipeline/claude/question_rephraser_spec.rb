RSpec.describe AnswerComposition::Pipeline::Claude::QuestionRephraser, :aws_credentials_stubbed do
  let(:conversation) { create :conversation, :with_history }
  let(:question) { conversation.questions.strict_loading(false).last }
  let(:context) { build(:answer_pipeline_context, question:) }
  let(:question_records) { conversation.questions.joins(:answer).order(created_at: :asc) }
  let(:rephrased) { "How do I pay my corporation tax" }

  it_behaves_like "a claude answer composition component with a configurable model", "BEDROCK_CLAUDE_QUESTION_REPHRASER_MODEL" do
    let(:pipeline_step) { described_class.new(question.message, question_records) }
    let(:stubbed_request) do
      stub_claude_question_rephrasing(
        question.message,
        rephrased,
        chat_options: { bedrock_model: described_class.bedrock_model },
      )
    end
  end

  context "when there is a valid response from Claude" do
    it "includes the current question in the user prompt" do
      anthropic_request = stub_claude_question_rephrasing(question.message, rephrased)
      described_class.call(question.message, question_records)

      expect(anthropic_request).to have_been_made
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

      anthropic_request = stub_claude_question_rephrasing(
        Regexp.new(message_history),
        rephrased,
      )

      described_class.call(question.message, question_records)

      expect(anthropic_request).to have_been_made
    end

    it "returns a result object" do
      stub_claude_question_rephrasing(question.message, rephrased)
      result = described_class.call(question.message, question_records)

      llm_response = result.llm_response
      expect(llm_response[:stop_reason]).to eq(:end_turn)
      expect(llm_response[:content][0][:text]).to eq(rephrased)
      expect(result.rephrased_question).to eq(rephrased)
      expect(result.metrics).to eq({
        llm_prompt_tokens: 10,
        llm_completion_tokens: 20,
        llm_cached_tokens: nil,
        model: BedrockModels.model_id(:claude_sonnet_4_0),
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

      anthropic_request = stub_claude_question_rephrasing(
        Regexp.new(message_history),
        "A second rephrased question",
      )

      described_class.call(question.message, conversation.questions.joins(:answer))

      expect(anthropic_request).to have_been_made
    end
  end

  it "uses an overridden AWS region if set" do
    ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
      allow(Anthropic::BedrockClient).to receive(:new).and_call_original
      anthropic_request = stub_claude_question_rephrasing(question.message, rephrased)

      described_class.call(question.message, question_records)

      expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
      expect(anthropic_request).to have_been_made
    end
  end
end
