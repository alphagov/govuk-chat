RSpec.describe AutoEvaluation::Faithfulness::ReasonGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:score) { 0.5 }
    let(:verdicts) do
      [
        { "verdict" => "no", "reason" => "The retrieval context states Einstein won in 1921, not 1968." },
        { "verdict" => "yes" },
      ]
    end
    let(:contradictions) { ["The retrieval context states Einstein won in 1921, not 1968."] }
    let(:reason) { "The score is 0.5 because the answer incorrectly stated the year Einstein won the Nobel Prize." }
    let(:reason_json) do
      { reason: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.faithfulness.fetch(:reason) }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:user_prompt),
        score:,
        contradictions:,
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

      result = described_class.call(score:, verdicts:)

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
