RSpec.describe AnswerComposition::Pipeline::OpenAI::QuestionRephraser do # rubocop:disable RSpec/SpecFilePathFormat
  let(:conversation) { create :conversation, :with_history }
  let(:question) { conversation.questions.strict_loading(false).last }
  let(:question_records) { conversation.questions.joins(:answer).order("answers.created_at") }

  context "when there is a valid response from OpenAI" do
    let(:message_history) do
      <<~HISTORY.strip
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
    end
    let(:rephrased) { "How do I pay my corporation tax" }

    it "includes the current question in the user prompt" do
      request = stub_openai_chat_completion(Regexp.new(question.message))
      described_class.call(question.message, question_records)
      expect(request).to have_been_made
    end

    it "includes the message history in the user prompt" do
      request = stub_openai_chat_completion(Regexp.new(message_history))
      described_class.call(question.message, question_records)
      expect(request).to have_been_made
    end

    it "returns a result object" do
      stub_openai_chat_completion(Regexp.new(question.message), answer: rephrased)

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
        model: "gpt-4o-mini-2024-07-18",
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
