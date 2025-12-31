RSpec.describe AutoEvaluation::AnswerRelevancy::StatementGenerator, :aws_credentials_stubbed do
  describe ".call" do
    let(:answer_message) { "This is a test answer message." }
    let(:statements) { ["This is the first statement.", "This is the second statement."] }
    let(:statements_json) do
      { statements: }.to_json
    end
    let(:prompts) { AutoEvaluation::Prompts.config.answer_relevancy.fetch(:statements) }
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
        statements_json,
      )
    end

    it "returns an array with the statements, llm_response, and metrics" do
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
        statements,
        expected_llm_response,
        expected_metrics,
      )
    end
  end
end
