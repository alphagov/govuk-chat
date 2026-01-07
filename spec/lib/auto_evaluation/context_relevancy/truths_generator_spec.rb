RSpec.describe AutoEvaluation::ContextRelevancy::TruthsGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:answer_sources) do
      [
        build(
          :answer_source,
          chunk: build(
            :answer_source_chunk,
            title: "Applying for Home Energy Grants",
            description: "Find out how to apply for grants to improve the energy efficiency of your home.",
            heading_hierarchy: ["Application Process"],
            html_content: "<p>Application processes for energy grants may vary by region; always use official channels to submit your application to avoid scams.</p>",
          ),
        ),
        build(
          :answer_source,
          chunk: build(
            :answer_source_chunk,
            title: "Applying for Home Energy Grants",
            description: "Find out how to apply for grants to improve the energy efficiency of your home.",
            heading_hierarchy: %w[Overview Eligibility],
            html_content: "<p>Government grants for home energy improvements can help reduce your bills and increase your property's value. Check eligibility criteria on the official website.</p>",
          ),
        ),
      ]
    end
    let(:formatted_retrieval_context) do
      <<~CONTEXT
        # Context
        Page title: Applying for Home Energy Grants
        Description: Find out how to apply for grants to improve the energy efficiency of your home.
        Headings: Application Process
        # Content
        Application processes for energy grants may vary by region; always use official channels to submit your application to avoid scams.


        # Context
        Page title: Applying for Home Energy Grants
        Description: Find out how to apply for grants to improve the energy efficiency of your home.
        Headings: Overview > Eligibility
        # Content
        Government grants for home energy improvements can help reduce your bills and increase your property's value. Check eligibility criteria on the official website.
      CONTEXT
    end

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

    let(:truths_json) do
      { truths: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.context_relevancy.fetch(:truths) }
    let(:user_prompt) do
      sprintf(prompts.fetch(:user_prompt), retrieval_context: formatted_retrieval_context)
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

      result = described_class.call(answer_sources:)

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
