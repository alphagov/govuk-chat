RSpec.describe AnswerAnalysisGeneration::Metrics::AnswerRelevancy::VerdictsGenerator do
  describe ".call" do
    let(:question_message) { "This is a test question message." }
    let(:statements) { ["Statement one.", "Statement two."] }
    let(:verdicts) do
      [
        { "verdict" => "Yes" },
        { "verdict" => "No", "reason" => "The statement is irrelevant." },
      ]
    end

    before { stub_bedrock_converse(bedrock_converse_client_response(content: { verdicts: }.to_json)) }

    it "calls the BedrockConverseClient with the expected prompt" do
      expected_system_prompt = sprintf(
        Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy["verdicts"]["system_prompt"],
        question: question_message,
        statements:,
      )
      expect(BedrockConverseClient).to receive(:converse)
                                   .with(expected_system_prompt)
                                   .and_call_original

      described_class.call(question_message:, statements:)
    end

    it "returns a results object with the expected verdicts" do
      result = described_class.call(question_message:, statements:)
      expect(result)
        .to be_a(AnswerAnalysisGeneration::Metrics::AnswerRelevancy::VerdictsGenerator::Result)
        .and have_attributes(verdicts:)
    end

    it "returns a results object with the LLM response" do
      result = described_class.call(question_message:, statements:)

      expected_result = bedrock_converse_client_response(content: { verdicts: }.to_json).to_h
      expect(result.llm_response).to eq(expected_result)
    end

    it "returns a results object with the metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)
      result = described_class.call(question_message:, statements:)

      expect(result.metrics)
        .to eq({
          duration: 2.0,
          model: AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric::MODEL,
          llm_prompt_tokens: 25,
          llm_completion_tokens: 35,
        })
    end
  end
end
