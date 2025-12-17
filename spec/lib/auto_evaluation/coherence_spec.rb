RSpec.describe AutoEvaluation::Coherence, :aws_credentials_stubbed do
  describe ".call" do
    let(:prompts) { AutoEvaluation::Prompts.config.coherence }
    let(:question) { build(:question, message: question_message) }
    let(:answer) { build(:answer,  question:, message: answer_message) }
    let(:question_message) { "This is a test question message." }
    let(:answer_message) { "This is a test answer message." }
    let(:reason) { "This is the reason for the score." }
    let(:response_json) { { score: 3, reason: }.to_json }
    let(:user_prompt) do
      sprintf(
        prompts.fetch(:user_prompt),
        answer: answer_message,
        question: question_message,
      )
    end
    let(:tools) { [prompts.fetch(:tool_spec)] }

    it "returns a results object with the expected attributes" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)
      stub = stub_bedrock_invoke_model_openai_oss_tool_call(
        user_prompt,
        tools,
        response_json,
      )

      result = described_class.call(answer)

      expected_metrics = {
        coherence: {
          duration: 2.0,
          model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
          llm_prompt_tokens: 25,
          llm_completion_tokens: 35,
          llm_cached_tokens: nil,
        },
      }
      expect(result)
        .to be_a(AutoEvaluation::ScoreResult)
        .and have_attributes(
          score: 0.5,
          reason:,
          success: false,
          llm_responses: { coherence: JSON.parse(stub.response.body) },
          metrics: expected_metrics,
        )
    end

    it "returns the correct score and success for each rubric score" do
      {
        1 => 0.0,
        2 => 0.25,
        3 => 0.5,
        4 => 0.75,
        5 => 1.0,
      }.each do |rubric_score, expected_score|
        response_json = { score: rubric_score, reason: }.to_json
        stub_bedrock_invoke_model_openai_oss_tool_call(
          user_prompt,
          tools,
          response_json,
        )

        result = described_class.call(answer)

        expect(result.score).to eq(expected_score)
        expect(result.success).to eq(expected_score >= described_class::THRESHOLD)
      end
    end

    context "when the answer has a rephrased question" do
      let(:question_message) { "This is a rephrased test question." }
      let(:answer) { build(:answer, message: answer_message, rephrased_question: question_message) }

      it "uses the rephrased question in the prompt" do
        stub = stub_bedrock_invoke_model_openai_oss_tool_call(
          user_prompt,
          tools,
          response_json,
        )

        described_class.call(answer)

        expect(stub).to have_been_requested
      end
    end
  end
end
