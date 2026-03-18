RSpec.describe AutoEvaluation::Coherence, :aws_credentials_stubbed do
  describe ".call" do
    let(:prompts) { AutoEvaluation::Prompts.config.coherence }
    let(:question) { build(:question, message: question_message) }
    let(:answer) { build(:answer,  question:, message: answer_message) }
    let(:question_message) { "This is a test question message." }
    let(:answer_message) { "This is a test answer message." }
    let(:reason) { "This is the reason for the score." }
    let(:llm_response) { { score: 3, reason: } }

    it "returns a results object with the expected attributes" do
      allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)
      stub = stub_bedrock_invoke_model_openai_oss_coherence(
        answer_message:,
        question_message:,
        llm_response:,
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
        .to be_a(AutoEvaluation::Result)
        .and have_attributes(
          score: 0.5,
          reason:,
          llm_responses: { coherence: JSON.parse(stub.response.body) },
          metrics: expected_metrics,
        )
    end

    it "returns the correct score and status for each rubric score" do
      {
        1 => 0.0,
        2 => 0.25,
        3 => 0.5,
        4 => 0.75,
        5 => 1.0,
      }.each do |rubric_score, expected_score|
        llm_response = { score: rubric_score, reason: }
        stub_bedrock_invoke_model_openai_oss_coherence(
          answer_message:,
          question_message:,
          llm_response:,
        )

        result = described_class.call(answer)

        expected_status = expected_score >= described_class::THRESHOLD ? "success" : "failure"
        expect(result.score).to eq(expected_score)
        expect(result.status).to eq(expected_status)
      end
    end

    context "when a BedrockOpenAIOssInvoke::InvalidToolCallError is raised" do
      let(:error_message) { "Some error message" }

      it "returns a result object with the expected attributes" do
        allow(AutoEvaluation::BedrockOpenAIOssInvoke).to receive(:call)
                                             .and_raise(
                                               AutoEvaluation::BedrockOpenAIOssInvoke::InvalidToolCallError.new(error_message),
                                             )

        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::Result)
          .and have_attributes(
            status: "error",
            score: nil,
            reason: nil,
            error_message: error_message,
            llm_responses: {},
            metrics: {},
          )
      end
    end
  end
end
