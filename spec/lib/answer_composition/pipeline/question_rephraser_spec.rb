RSpec.describe AnswerComposition::Pipeline::QuestionRephraser do
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
        stub_openai_chat_completion(expected_messages, answer: rephrased)
      end

      it "updates the contexts question_message with the rephrased question" do
        described_class.call(context)
        expect(context.question_message).to eq(rephrased)
      end

      it "assigns metrics to the answer" do
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

        described_class.call(context)

        expect(context.answer.metrics["question_rephrasing"]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 13,
          llm_completion_tokens: 7,
          llm_cached_tokens: 10,
        })
      end

      it "assigns the llm response to the answer" do
        described_class.call(context)
        expect(context.answer.llm_responses["question_rephrasing"]).to match(
          a_hash_including(
            "finish_reason" => "stop",
            "message" => a_hash_including({ "content" => rephrased }),
          ),
        )
      end

      context "and one of the answers statuses is in Answer::STATUSES_EXCLUDED_FROM_REPHRASING" do
        it "does not include that question and answer in the history" do
          request = stub_openai_chat_completion(expected_messages, answer: rephrased)
          last_question = conversation.questions.strict_loading(false).last
          create(:answer, question: last_question, status: :abort_jailbreak_guardrails)
          create(:question, conversation:, message: last_question.message)

          described_class.call(context)
          expect(request).to have_been_made
        end
      end
    end

    context "when a question has been rephrased" do
      let(:conversation) { create(:conversation) }
      let(:question) { create(:question, conversation:) }
      let(:context) { build(:answer_pipeline_context, question:) }
      let(:answer) { build(:answer, rephrased_question: "A rephrased question") }

      before { create(:question, conversation:, answer:) }

      it "includes the rephrased question in the history" do
        request = stub_openai_question_rephrasing(answer.rephrased_question, "Answer from OpenAI")
        described_class.call(context)
        expect(request).to have_been_made
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

      it "truncates the history to the last 5 Q/A pairs" do # rubocop:disable RSpec/NoExpectationExample
        rephrased = "How do I pay my corporation tax"
        stub_openai_chat_completion(expected_messages, answer: rephrased)
        described_class.call(context)
      end
    end
  end

  def config
    Rails.configuration.llm_prompts.question_rephraser
  end
end
