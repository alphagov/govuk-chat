RSpec.describe AutoEvaluation::ContextRelevancy::VerdictsGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:truths) do
      [
        {
          "context" => "Home energy grant application process",
          "facts" => [
            "Application processes for energy grants may vary by region.",
            "You should always use official channels to submit your application to avoid scams.",
          ],
        },
        {
          "context" => "Home energy grant eligibility",
          "facts" => [
            "Government grants for home energy improvements can help reduce your bills.",
            "Government grants for home energy improvements can increase your property's value.",
          ],
        },
      ]
    end
    let(:formatted_truths) do
      truths.map do |truth|
        <<~TRUTH
          Context: #{truth['context']}
          Facts:
          #{truth['facts'].join("\n")}
        TRUTH
      end
    end
    let(:information_needs) do
      [
        "The government schemes available to help with heating or energy bills.",
        "Eligibility criteria for receiving heating bill support.",
        "How to apply for heating bill support.",
      ]
    end
    let(:verdicts) do
      [
        {
          "verdict" => "yes",
          "reason" => "The facts mention Government grants for home energy improvements can help reduce your bills, indicating that such government schemes exist.",
        },
        {
          "verdict" => "no",
          "reason" => "The provided facts only state that eligibility criteria can be checked on the official website.",
        },
        {
          "verdict" => "yes",
          "reason" => "The facts describe the application process.",
        },
      ]
    end
    let(:verdicts_json) do
      { verdicts: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.context_relevancy.fetch(:verdicts) }
    let(:user_prompt) do
      sprintf(prompts.fetch(:user_prompt), truths: formatted_truths, information_needs: information_needs.join("\n"))
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

      result = described_class.call(truths:, information_needs:)

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
