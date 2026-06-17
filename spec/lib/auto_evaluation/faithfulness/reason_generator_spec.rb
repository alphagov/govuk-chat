RSpec.describe AutoEvaluation::Faithfulness::ReasonGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:score) { 0.0 }
    let(:verdicts) do
      [
        { "verdict" => "no", "reason" => "The retrieval context states Einstein won in 1921, not 1968." },
        { "verdict" => "idk", "reason" => "The retrieval context does not explicitly confirm or deny that Einstein won the Nobel Prize for the photoelectric effect." },
      ]
    end
    let(:unfaithful_claims) do
      [
        "(Contradiction) #{verdicts.first['reason']}",
        "(Ambiguous) #{verdicts.second['reason']}",
      ]
    end
    let(:reason) { "The score is 0.0 because the answer incorrectly stated the year Einstein won the Nobel Prize." }
    let(:reason_json) do
      { reason: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.faithfulness.fetch(:reason) }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:new_user_prompt),
        score:,
        unfaithful_claims:,
      )
    end
    let(:tool) { prompts.fetch(:new_tool_spec) }
    let!(:stub_bedrock) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tool,
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
