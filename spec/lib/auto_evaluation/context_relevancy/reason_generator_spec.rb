RSpec.describe AutoEvaluation::ContextRelevancy::ReasonGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:score) { 0.5 }
    let(:question_message) { "Can I get financial help for my heating bills?" }
    let(:verdicts) do
      [
        {
          "verdict" => "no",
          "reason" => "The facts only note that eligibility criteria can be checked on the official website.",
        },
        {
          "verdict" => "yes",
          "reason" => "The facts state that government grants for home energy improvements exist and can help reduce your bills",
        },
      ]
    end
    let(:unmet_needs) do
      verdicts.select { |verdict| verdict["verdict"].strip.downcase == "no" }
              .map { |verdict| verdict["reason"] }
    end
    let(:reason) { "The score is 0.5 because of some reason." }
    let(:reason_json) do
      { reason: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.context_relevancy.fetch(:reason) }
    let(:user_prompt) do
      sprintf(prompts.fetch(:user_prompt), score:, question: question_message, unmet_needs: unmet_needs.join("\n"))
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

      result = described_class.call(score:, question_message:, verdicts:)

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
