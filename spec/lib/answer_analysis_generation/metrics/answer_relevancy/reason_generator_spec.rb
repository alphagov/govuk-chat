RSpec.describe AnswerAnalysisGeneration::Metrics::AnswerRelevancy::ReasonGenerator do
  describe ".call" do
    let(:question_message) { "This is a test question message." }
    let(:score) { 0.5 }
    let(:verdicts) do
      [
        { "verdict" => "Yes" },
        { "verdict" => "No", "reason" => "The statement is irrelevant." },
      ]
    end
    let(:reason_json) do
      { reason: "This is the reason for the score." }.to_json
    end

    before { stub_bedrock_converse(bedrock_converse_client_response(content: reason_json)) }

    it "calls the BedrockConverseClient with the expected prompt" do
      expected_system_prompt = sprintf(
        Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy["reason"]["system_prompt"],
        score:,
        irrelevant_statements: ["The statement is irrelevant."],
        question: question_message,
      )
      expect(BedrockConverseClient).to receive(:call).with(
        messages: [{ role: "user", content: [{ text: expected_system_prompt }] }],
      ).and_call_original

      described_class.call(question_message:, verdicts:, score:)
    end

    it "returns a results object with the expected reason" do
      result = described_class.call(question_message:, verdicts:, score:)
      expect(result)
        .to be_a(AnswerAnalysisGeneration::Metrics::AnswerRelevancy::ReasonGenerator::Result)
        .and have_attributes(
          reason: "This is the reason for the score.",
        )
    end

    it "returns a results object with the LLM response" do
      result = described_class.call(question_message:, verdicts:, score:)

      expected_result = bedrock_converse_client_response(content: reason_json).to_h
      expect(result.llm_response).to eq(expected_result)
    end

    it "returns a results object with the metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)
      result = described_class.call(question_message:, verdicts:, score:)

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
