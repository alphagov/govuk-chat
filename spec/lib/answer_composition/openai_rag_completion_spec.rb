RSpec.describe AnswerComposition::OpenaiRagCompletion do
  around do |example|
    ClimateControl.modify(
      OPENAI_ACCESS_TOKEN: "open-ai-access-token",
    ) do
      example.run
    end
  end

  describe ".call" do
    let(:question) { create :question }
    let(:expected_message_history) do
      [
        { role: "system", content: system_prompt },
        { role: "user", content: question.message },
      ]
    end

    it "calls OpenAI chat endpoint and returns unsaved answer" do
      stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")
      stub_search_api(%w[some context here])
      result = described_class.call(question)
      expect(result).to be_a(Answer)
      expect(result).to have_attributes(
        question:,
        message: "OpenAI responded with...",
        status: "success",
      )
      expect(result.persisted?).to eq(false)
    end

    context "when the question contains a forbidden word" do
      let(:question) { build_stubbed(:question, message: user_input) }
      let(:user_input) { "I want to know about forbidden_word" }

      it "returns an answer with a forbidden words message" do
        allow(Rails.configuration).to receive(:question_forbidden_words).and_return(%w[forbidden_word])

        answer = described_class.call(question)
        expect(answer).to have_attributes(
          question:,
          message: described_class::FORBIDDEN_WORDS_RESPONSE,
          status: "abort_forbidden_words",
        )
      end
    end

  private

    def system_prompt
      <<~OUTPUT
        #{AnswerComposition::Prompts::GOVUK_DESIGNER}

        Context:
        some
        context
        here

      OUTPUT
    end

    # Temp - we will stub the real thing when we've built it
    def stub_search_api(result = [])
      allow(Retrieval::SearchApiV1Retriever).to receive(:call).and_return(result)
    end
  end
end
