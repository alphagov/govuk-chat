RSpec.describe AutoEvaluation::AnswerRelevancy::StatementGenerator do
  describe ".call" do
    let(:answer_message) { "This is a test answer message." }
    let(:statements) { ["This is the first statement.", "This is the second statement."] }
    let(:statements_json) do
      { statements: }.to_json
    end

    before { stub_bedrock_converse(bedrock_converse_client_response(content: statements_json)) }

    it "calls AutoEvaluation::BedrockConverseAutoEvaluation with the expected prompt" do
      expected_user_prompt = sprintf(
        Rails.configuration.govuk_chat_private
                            .llm_prompts
                            .auto_evaluation
                            .answer_relevancy["statements"]["user_prompt"],
        answer: answer_message,
      )
      expect(AutoEvaluation::BedrockConverseAutoEvaluation).to receive(:call)
                                                           .with(expected_user_prompt)
                                                           .and_call_original

      described_class.call(answer_message:)
    end

    it "returns an array with the statements, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(answer_message:)

      expected_llm_responses = bedrock_converse_client_response(content: statements_json).to_h
      expected_metrics = {
        duration: 2.0,
        model: AutoEvaluation::BedrockConverseAutoEvaluation::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expect(result).to contain_exactly(
        statements,
        expected_llm_responses,
        expected_metrics,
      )
    end
  end
end
