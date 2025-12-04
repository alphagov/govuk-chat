RSpec.describe AnswerAnalysisGeneration::Metrics::AnswerRelevancy::StatementGenerator do
  describe ".call" do
    let(:answer_message) { "This is a test answer message." }
    let(:statements_json) do
      { statements: ["This is the first statement.", "This is the second statement."] }.to_json
    end

    before { stub_bedrock_converse(bedrock_converse_client_response(content: statements_json)) }

    it "calls the AnswerAnalysisGeneration::Metrics::BedrockConverseClient with the expected prompt" do
      expected_system_prompt = sprintf(
        Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy["statements"]["system_prompt"],
        answer: answer_message,
      )
      expect(AnswerAnalysisGeneration::Metrics::BedrockConverseClient).to receive(:converse)
                                   .with(expected_system_prompt)
                                   .and_call_original

      described_class.call(answer_message:)
    end

    it "returns a results object with the expected statements" do
      result = described_class.call(answer_message:)
      expect(result)
        .to be_a(AnswerAnalysisGeneration::Metrics::AnswerRelevancy::StatementGenerator::Result)
        .and have_attributes(
          statements: ["This is the first statement.", "This is the second statement."],
        )
    end

    it "returns a results object with the LLM response" do
      result = described_class.call(answer_message:)

      expected_result = bedrock_converse_client_response(content: statements_json).to_h
      expect(result.llm_response).to eq(expected_result)
    end

    it "returns a results object with the metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)
      result = described_class.call(answer_message:)

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
