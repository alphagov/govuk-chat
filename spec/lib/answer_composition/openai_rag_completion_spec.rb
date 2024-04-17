RSpec.describe AnswerComposition::OpenAIRagCompletion, :chunked_content_index do # rubocop:disable RSpec/FilePath
  around do |example|
    ClimateControl.modify(
      OPENAI_ACCESS_TOKEN: "open-ai-access-token",
    ) do
      example.run
    end
  end

  describe ".call" do
    let(:rephrased_question) { "Question rephrased by OpenAI" }
    let(:question) { create :question }
    let(:expected_message_history) do
      [
        { role: "system", content: system_prompt },
        { role: "user", content: rephrased_question },
      ]
    end
    let(:opensearch_chunk) { build(:chunked_content_record).except(:openai_embedding).merge(_id: "1", score: 1.0) }
    let(:chunk_result) { Search::ChunkedContentRepository::Result.new(**opensearch_chunk) }

    before do
      allow(AnswerComposition::QuestionRephraser).to receive(:call).and_return(rephrased_question)
      allow(Search::ResultsForQuestion).to receive(:call).and_return([chunk_result])
    end

    context "when the question has been rephrased" do
      it "calls OpenAI chat endpoint and returns unsaved answer" do
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: "OpenAI responded with...",
            rephrased_question:,
            status: "success",
          },
        )
      end
    end

    context "when rephrasing produces the same question" do
      let(:expected_message_history) do
        [
          { role: "system", content: system_prompt },
          { role: "user", content: question.message },
        ]
      end

      before do
        allow(AnswerComposition::QuestionRephraser).to receive(:call).and_return(question.message)
      end

      it "calls OpenAI chat endpoint and returns unsaved answer with rephrased_question: nil" do
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: "OpenAI responded with...",
            rephrased_question: nil,
            status: "success",
          },
        )
      end
    end

    context "when the rephrased question contains a forbidden word" do
      let(:question) { build_stubbed(:question, message: user_input) }
      let(:rephrased_question) { "Question about forbidden_word rephrased by OpenAI" }
      let(:user_input) { "I want to know about forbidden_word" }

      it "returns an answer with a forbidden words message" do
        allow(Rails.configuration).to receive(:question_forbidden_words).and_return(%w[forbidden_word])

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: described_class::FORBIDDEN_WORDS_RESPONSE,
            rephrased_question:,
            status: "abort_forbidden_words",
          },
        )
      end
    end

    context "when OpenAI raises a ContextLengthExceededError" do
      it "returns an unsaved answer with the error_context_length_exceeded status" do
        allow(GovukError).to receive(:notify)
        stub_openai_chat_completion_error(status: 400, code: "context_length_exceeded")

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: AnswerComposition::Composer::UNSUCCESSFUL_REQUEST_MESSAGE,
            status: "error_context_length_exceeded",
            error_message: "class: OpenAIClient::ContextLengthExceededError message: Error message",
          },
        )
        expect(GovukError).to have_received(:notify).with(OpenAIClient::ContextLengthExceededError)
      end
    end

    context "when OpenAIClient raises a RequestError" do
      it "returns an unsaved answer with a generic unsuccessful request message which captures the error" do
        allow(GovukError).to receive(:notify)
        stub_openai_chat_completion_error

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: AnswerComposition::Composer::UNSUCCESSFUL_REQUEST_MESSAGE,
            status: "error_answer_service_error",
            error_message: "class: OpenAIClient::ClientError message: Error message",
          },
        )
        expect(GovukError).to have_received(:notify).with(OpenAIClient::RequestError)
      end
    end

  private

    def system_prompt
      <<~OUTPUT
        #{AnswerComposition::Prompts::GOVUK_DESIGNER}

        Context:
        <p>Some content</p>

      OUTPUT
    end

    def expect_unsaved_answer_with_attributes(answer, attributes = {})
      expected_attributes = attributes.merge(persisted?: false)

      expect(answer).to be_a(Answer)
      expect(answer).to have_attributes(**expected_attributes)
    end
  end
end
