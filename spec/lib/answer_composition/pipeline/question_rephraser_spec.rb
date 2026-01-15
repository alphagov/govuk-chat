RSpec.describe AnswerComposition::Pipeline::QuestionRephraser do
  let(:instance) { described_class.new(llm_provider: :claude) }
  let(:rephrasing_result) do
    described_class::Result.new(
      llm_response: { stop_reason: "end_turn" },
      rephrased_question: "Rephrased question",
      metrics: { llm_prompt_tokens: 10, llm_completion_tokens: 20 },
    )
  end

  before do
    allow(AnswerComposition::Pipeline::Claude::QuestionRephraser).to(
      receive(:call).and_return(rephrasing_result),
    )
  end

  context "when the question is the beginning of the conversation" do
    let(:context) { build(:answer_pipeline_context) }

    it "returns nil" do
      expect(instance.call(context)).to be_nil
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

      expect(instance.call(context)).to be_nil
    end
  end

  context "when the question is part of an ongoing chat" do
    let(:conversation) { create :conversation, :with_history }
    let(:context) { build(:answer_pipeline_context, question:) }
    let(:question) { conversation.questions.strict_loading(false).last }
    let(:question_records_for_rephrasing) do
      conversation.questions.joins(:answer).order("answers.created_at")
    end

    it "raises an error if the llm_provider is unknown" do
      expect { described_class.new(llm_provider: :unknown).call(context) }
        .to raise_error("Unknown llm provider: unknown")
    end

    it "calls the OpenAI rephraser" do
      expect(AnswerComposition::Pipeline::OpenAI::QuestionRephraser).to(
        receive(:call).with(question.message, question_records_for_rephrasing),
      ).and_return(rephrasing_result)

      described_class.new(llm_provider: :openai).call(context)
    end

    it "calls the Claude rephraser" do
      expect(AnswerComposition::Pipeline::Claude::QuestionRephraser).to(
        receive(:call).with(question.message, question_records_for_rephrasing),
      )

      instance.call(context)
    end

    it "updates the context's question_message with the rephrased question" do
      instance.call(context)
      expect(context.question_message).to eq("Rephrased question")
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      instance.call(context)

      expect(context.answer.metrics["question_rephrasing"])
        .to eq(rephrasing_result.metrics.merge(duration: 1.5))
    end

    it "assigns the llm response to the answer" do
      instance.call(context)

      expect(context.answer.llm_responses["question_rephrasing"])
        .to eq(rephrasing_result.llm_response)
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
          created_at: rand(0..10).days.ago,
        )
      end
    end

    it "truncates the history to the last 5 Q/A pairs" do
      question_records_for_rephrasing = conversation
                                        .questions
                                        .joins(:answer)
                                        .sort_by(&:created_at)
                                        .last(5)

      expect(AnswerComposition::Pipeline::Claude::QuestionRephraser).to(
        receive(:call).with("Question 7", question_records_for_rephrasing),
      )

      instance.call(context)
    end
  end
end
