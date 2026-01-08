RSpec.describe AutoEvaluation::Faithfulness::VerdictsGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:claims) { ["Einstein won the Nobel Prize in 1968.", "Einstein won the Nobel Prize for the photoelectric effect."] }
    let(:truths) { ["Einstein won the Nobel Prize in 1921 for the photoelectric effect."] }
    let(:verdicts) do
      [
        { "verdict" => "no", "reason" => "The retrieval context states Einstein won in 1921, not 1968." },
        { "verdict" => "yes" },
      ]
    end
    let(:verdicts_json) do
      { verdicts: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.faithfulness.fetch(:verdicts) }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:user_prompt),
        claims:,
        retrieval_context: truths.join("\n\n"),
      )
    end
    let(:tools) { [prompts.fetch(:tool_spec)] }
    let!(:stub_bedrock) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tools,
        verdicts_json,
      )
    end

    it "returns an array with the verdicts, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(claims:, truths:)

      expected_llm_response = JSON.parse(stub_bedrock.response.body)
      expected_metrics = {
        duration: 2.0,
        model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expect(result).to contain_exactly(
        verdicts,
        expected_llm_response,
        expected_metrics,
      )
    end
  end
end
