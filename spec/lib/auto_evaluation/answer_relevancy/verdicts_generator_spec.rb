RSpec.describe AutoEvaluation::AnswerRelevancy::VerdictsGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:question_message) { "This is a test question message." }
    let(:statements) { ["Statement one.", "Statement two."] }
    let(:verdicts) do
      [
        { "verdict" => "yes" },
        { "verdict" => "no", "reason" => "The statement is irrelevant." },
      ]
    end
    let(:verdicts_json) do
      { verdicts: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.answer_relevancy.fetch(:verdicts) }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:user_prompt),
        question: question_message,
        statements:,
      )
    end
    let(:tools) { [prompts.fetch(:tool_spec)] }
    let!(:stub_bedrock) do
      bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tools,
        verdicts_json,
      )
    end

    it "returns an array with the verdicts, llm_response, and metrics" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

      result = described_class.call(question_message:, statements:)

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
