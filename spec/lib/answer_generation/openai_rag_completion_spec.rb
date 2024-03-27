RSpec.describe AnswerGeneration::OpenaiRagCompletion do
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
      )
      expect(result.persisted?).to eq(false)
    end

  private

    def system_prompt
      <<~OUTPUT
        #{AnswerGeneration::Prompts::GOVUK_DESIGNER}

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
