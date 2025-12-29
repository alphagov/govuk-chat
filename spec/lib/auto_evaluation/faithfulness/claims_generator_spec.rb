RSpec.describe AutoEvaluation::Faithfulness::ClaimsGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:answer_message) { "Einstein won the Nobel Prize in 1968 for the photoelectric effect." }
    let(:claims) { ["Einstein won the Nobel Prize in 1968.", "Einstein won the Nobel Prize for the photoelectric effect."] }
    let(:claims_json) do
      { claims: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.faithfulness.fetch(:claims) }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:user_prompt),
        answer: answer_message,
      )
    end
    let(:tools) { [prompts.fetch(:tool_spec)] }
    let!(:stub_bedrock) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tools,
        claims_json,
      )
    end

    it "returns an array with the claims, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(answer_message:)

      expected_llm_response = JSON.parse(stub_bedrock.response.body)
      expected_metrics = {
        duration: 2.0,
        model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expect(result).to contain_exactly(
        claims,
        expected_llm_response,
        expected_metrics,
      )
    end
  end
end
