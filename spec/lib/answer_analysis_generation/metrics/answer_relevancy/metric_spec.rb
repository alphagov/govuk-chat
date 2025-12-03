RSpec.describe AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric do
  describe ".call" do
    let(:question_message) { "This is a test question message." }
    let(:answer_message) { "This is a test answer message." }
    let(:statements) { ["This is the first statement.", "This is the second statement."] }
    let(:statements_json) { { statements: }.to_json }
    let(:verdicts) do
      [
        { "verdict" => "Yes" },
        { "verdict" => "No", "reason" => "The statement is irrelevant." },
      ]
    end
    let(:verdicts_json) { { verdicts: }.to_json }
    let(:reason) { "This is the reason for the score." }
    let(:reason_json) { { reason: }.to_json }

    before do
      stub_bedrock_converse(
        bedrock_converse_client_response(content: statements_json),
        bedrock_converse_client_response(content: verdicts_json),
        bedrock_converse_client_response(content: reason_json),
      )
    end

    it "returns a results object with the expected attributes" do
      allow(Clock).to receive(:monotonic_time)
                  .and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0)
      result = described_class.call(
        question_message:,
        answer_message:,
      )
      expected_llm_responses = {
        answer_relevancy_statements: bedrock_converse_client_response(content: statements_json).to_h,
        answer_relevancy_verdicts: bedrock_converse_client_response(content: verdicts_json).to_h,
        answer_relevancy_reason: bedrock_converse_client_response(content: reason_json).to_h,
      }
      shared_metrics_attributes = {
        duration: 2.0,
        model: described_class::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
      }
      expected_metrics = {
        answer_relevancy_statements: shared_metrics_attributes,
        answer_relevancy_verdicts: shared_metrics_attributes,
        answer_relevancy_reason: shared_metrics_attributes,
      }

      expect(result)
        .to be_a(AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric::Result)
        .and have_attributes(
          score: 0.5,
          reason:,
          success: true,
          llm_responses: expected_llm_responses,
          metrics: expected_metrics,
        )
    end

    it "has a configurable threshold for success" do
      result = described_class.call(
        question_message:,
        answer_message:,
        threshold: 0.6,
      )
      expect(result.success).to be false
    end

    context "when no statements are extracted from the answer" do
      let(:statements_json) { { statements: [] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)
        stub_bedrock_converse(
          bedrock_converse_client_response(content: statements_json),
        )

        result = described_class.call(
          question_message:,
          answer_message:,
        )

        expect(result)
          .to be_a(AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric::Result)
          .and have_attributes(
            score: 1.0,
            reason: "No statements were extracted from the answer.",
            success: true,
            llm_responses: {
              answer_relevancy_statements: bedrock_converse_client_response(content: statements_json).to_h,
            },
            metrics: { answer_relevancy_statements: {
              duration: 2.0,
              model: described_class::MODEL,
              llm_prompt_tokens: 25,
              llm_completion_tokens: 35,
            } },
          )
      end
    end

    context "when no verdicts are generated for the extracted statements" do
      let(:verdicts_json) { { verdicts: [] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time)
                    .and_return(200.0, 202.0, 204.0, 206.0)
        stub_bedrock_converse(
          bedrock_converse_client_response(content: statements_json),
          bedrock_converse_client_response(content: verdicts_json),
        )

        result = described_class.call(
          question_message:,
          answer_message:,
        )

        expected_llm_responses = {
          answer_relevancy_statements: bedrock_converse_client_response(content: statements_json).to_h,
          answer_relevancy_verdicts: bedrock_converse_client_response(content: verdicts_json).to_h,
        }
        expected_metrics = {
          answer_relevancy_statements: {
            duration: 2.0,
            model: described_class::MODEL,
            llm_prompt_tokens: 25,
            llm_completion_tokens: 35,
          },
          answer_relevancy_verdicts: {
            duration: 2.0,
            model: described_class::MODEL,
            llm_prompt_tokens: 25,
            llm_completion_tokens: 35,
          },
        }
        expect(result)
          .to be_a(AnswerAnalysisGeneration::Metrics::AnswerRelevancy::Metric::Result)
          .and have_attributes(
            score: 1.0,
            reason: "No verdicts were generated for the extracted statements.",
            success: true,
            llm_responses: expected_llm_responses,
            metrics: expected_metrics,
          )
      end
    end
  end
end
