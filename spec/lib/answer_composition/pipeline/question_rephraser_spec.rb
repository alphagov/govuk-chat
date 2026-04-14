RSpec.describe AnswerComposition::Pipeline::QuestionRephraser, :aws_credentials_stubbed do
  let(:conversation) { create :conversation, :with_history }
  let(:question) { conversation.questions.strict_loading(false).last }
  let(:context) { build(:answer_pipeline_context, question:) }
  let(:question_records) { conversation.questions.joins(:answer).order(created_at: :asc) }
  let(:rephrased) { "How do I pay my corporation tax" }
  let!(:stub) { stub_claude_question_rephrasing(question.message, rephrased) }

  it_behaves_like "a claude answer composition component with a configurable model", "BEDROCK_CLAUDE_QUESTION_REPHRASER_MODEL" do
    let(:pipeline_step) { described_class.new(context) }
    let(:stubbed_request_lambda) do
      lambda { |bedrock_model|
        stub_claude_question_rephrasing(
          question.message,
          rephrased,
          chat_options: { bedrock_model: },
        )
      }
    end
  end

  it "uses an overridden AWS region if set" do
    ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
      allow(Anthropic::BedrockClient).to receive(:new).and_call_original

      described_class.call(context)

      expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
      expect(stub).to have_been_requested
    end
  end

  context "when the question is the beginning of the conversation" do
    let(:context) { build(:answer_pipeline_context) }

    it "returns nil" do
      expect(described_class.call(context)).to be_nil
    end
  end

  context "when all other recent answers have statuses in Answer::STATUSES_EXCLUDED_FROM_REPHRASING" do
    it "returns nil" do
      conversation = create(:conversation)
      create(:question, conversation:)
      Answer::STATUSES_EXCLUDED_FROM_REPHRASING.sample(4) do |status|
        question = create(:question, conversation:)
        create(:answer, question:, status:)
      end
      latest_question = create(:question, conversation:)
      context = build(:answer_pipeline_context, question: latest_question)

      expect(described_class.call(context)).to be_nil
    end
  end

  context "when the question is part of an ongoing chat" do
    it "includes the current question in the user prompt" do
      described_class.call(context)
      expect(stub).to have_been_requested
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

      described_class.call(context)

      expect(anthropic_request).to have_been_made
    end

    it "updates the context's question_message with the rephrased question" do
      described_class.call(context)
      expect(context.question_message).to eq(rephrased)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["question_rephrasing"])
        .to eq({
          duration: 1.5,
          llm_prompt_tokens: 10,
          llm_completion_tokens: 20,
          llm_cached_tokens: nil,
          model: BedrockModels.model_id(:claude_sonnet_4_0),
        })
    end

    it "assigns the llm response to the answer" do
      described_class.call(context)

      expected_llm_response = claude_messages_response(
        content: [claude_messages_text_block(rephrased)],
        usage: claude_messages_usage_block(input_tokens: 10, output_tokens: 20),
      ).to_h

      expect(context.answer.llm_responses["question_rephrasing"])
        .to eq(expected_llm_response)
    end
  end

  context "with a long history" do
    let(:conversation) { create(:conversation) }
    let(:question) { create(:question, message: "Question 7", conversation:) }
    let(:context) { build(:answer_pipeline_context, question:) }

    before do
      (1..6).each do |n|
        answer = build(:answer, message: "Answer #{n}")
        create(
          :question,
          answer:,
          conversation:,
          message: "Question #{n}",
        )
      end
    end

    it "truncates the history to the last 5 Q/A pairs" do
      message_history = <<~HISTORY.strip
        user:
        """
        Question 2
        """
        assistant:
        """
        Answer 2
        """
        user:
        """
        Question 3
        """
        assistant:
        """
        Answer 3
        """
        user:
        """
        Question 4
        """
        assistant:
        """
        Answer 4
        """
        user:
        """
        Question 5
        """
        assistant:
        """
        Answer 5
        """
        user:
        """
        Question 6
        """
        assistant:
        """
        Answer 6
        """
      HISTORY

      anthropic_request = stub_claude_question_rephrasing(
        Regexp.new(message_history),
        rephrased,
      )

      described_class.call(context)

      expect(anthropic_request).to have_been_made
    end
  end

  context "when a question has been rephrased" do
    let(:previously_rephrased) { "A previously rephrased question" }
    let(:conversation) { create(:conversation) }
    let(:previous_question) { create(:question, conversation:) }
    let!(:answer) { create(:answer, question: previous_question, rephrased_question: previously_rephrased) }
    let(:question) { create(:question, conversation:) }

    it "includes the rephrased question in the history" do
      create(:question, conversation:)
      message_history = <<~HISTORY.strip
        user:
        """
        #{previously_rephrased}
        """
        assistant:
        """
        #{answer.message}
        """
      HISTORY

      anthropic_request = stub_claude_question_rephrasing(
        Regexp.new(message_history),
        rephrased,
      )

      described_class.call(context)

      expect(anthropic_request).to have_been_made
    end
  end
end
