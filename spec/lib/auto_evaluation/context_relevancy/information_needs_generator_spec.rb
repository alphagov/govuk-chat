RSpec.describe AutoEvaluation::ContextRelevancy::InformationNeedsGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:question) { "Can I get financial help for my heating bills?" }
    let(:information_needs) do
      [
        "The government schemes available to help with heating or energy bills.",
        "Eligibility criteria for receiving heating bill support.",
        "How to apply for heating bill support.",
      ]
    end
    let(:information_needs_json) do
      { information_needs: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.context_relevancy.fetch(:information_needs) }
    let(:user_prompt) do
      sprintf(prompts.fetch(:user_prompt), question:)
    end
    let(:tools) { [prompts.fetch(:tool_spec)] }
    let!(:stub_bedrock) do
      stub_bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tools,
        information_needs_json,
      )
    end

    it "returns an array with the information needs, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(question:)

      expected_llm_response = JSON.parse(stub_bedrock.response.body)
      expected_metrics = {
        duration: 2.0,
        model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expect(result).to contain_exactly(
        information_needs,
        expected_llm_response,
        expected_metrics,
      )
    end
  end
end
