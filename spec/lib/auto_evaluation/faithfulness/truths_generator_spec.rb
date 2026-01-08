RSpec.describe AutoEvaluation::Faithfulness::TruthsGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:retrieval_context) { "Einstein won the Nobel Prize in 1921 for the photoelectric effect." }
    let(:truths) { ["Einstein won the Nobel Prize in 1921.", "Einstein won the Nobel Prize for the photoelectric effect."] }
    let(:truths_json) do
      { truths: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.faithfulness.fetch(:truths) }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:user_prompt),
        retrieval_context:,
      )
    end
    let(:tools) { [prompts.fetch(:tool_spec)] }
    let!(:stub_bedrock) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tools,
        truths_json,
      )
    end

    it "returns an array with the truths, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(retrieval_context:)

      expected_llm_response = JSON.parse(stub_bedrock.response.body)
      expected_metrics = {
        duration: 2.0,
        model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expect(result).to contain_exactly(
        truths,
        expected_llm_response,
        expected_metrics,
      )
    end
  end
end
