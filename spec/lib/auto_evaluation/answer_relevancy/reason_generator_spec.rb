RSpec.describe AutoEvaluation::AnswerRelevancy::ReasonGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:question_message) { "This is a test question message." }
    let(:score) { 0.5 }
    let(:verdicts) do
      [
        { "verdict" => "Yes" },
        { "verdict" => "No", "reason" => "The statement is irrelevant." },
      ]
    end
    let(:reason) { "This is the reason for the score." }
    let(:reason_json) do
      { reason: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.answer_relevancy.fetch(:reason) }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:user_prompt),
        score:,
        unsuccessful_verdicts_reasons: ["The statement is irrelevant."],
        question: question_message,
      )
    end
    let(:tools) { [prompts.fetch(:tool_spec)] }
    let!(:stub_bedrock) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tools,
        reason_json,
      )
    end

    it "returns an array with the reason, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(question_message:, verdicts:, score:)
      expected_llm_response = JSON.parse(stub_bedrock.response.body)
      expected_metrics = {
        duration: 2.0,
        model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expect(result).to contain_exactly(
        reason,
        expected_llm_response,
        expected_metrics,
      )
    end
  end
end
