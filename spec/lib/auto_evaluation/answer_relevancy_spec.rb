RSpec.describe AutoEvaluation::AnswerRelevancy, :aws_credentials_stubbed do
  describe ".call" do
    let(:question_message) { "This is a test question message." }
    let(:answer_message) { "This is a test answer message." }
    let(:question) { build(:question, message: question_message) }
    let(:answer) { build(:answer, question:, message: answer_message) }

    let(:statements) { ["This is the first statement.", "This is the second statement."] }
    let(:statements_json) { { statements: }.to_json }
    let(:verdicts) do
      [
        { "verdict" => "yes" },
        { "verdict" => "no", "reason" => "The statement is irrelevant." },
      ]
    end
    let(:verdicts_json) { { verdicts: }.to_json }
    let(:reason) { "This is the reason for the score." }
    let(:reason_json) { { reason: }.to_json }
    let!(:answer_relevancy_stubs) do
      stub_bedrock_invoke_model_openai_oss_answer_relevancy(
        question_message:,
        answer_message:,
        statements_json:,
        verdicts_json:,
        reason_json:,
      )
    end
    let(:statements_stub) { answer_relevancy_stubs[:statements] }
    let(:verdicts_stub) { answer_relevancy_stubs[:verdicts] }
    let(:reason_stub) { answer_relevancy_stubs[:reason] }

    it "returns a results object with the expected attributes" do
      allow(Clock).to receive(:monotonic_time)
                  .and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0)

      result = described_class.call(answer)

      expected_llm_responses = {
        statements: JSON.parse(statements_stub.response.body),
        verdicts: JSON.parse(verdicts_stub.response.body),
        reason: JSON.parse(reason_stub.response.body),
      }
      shared_expected_metrics_attributes = {
        duration: 2.0,
        model: AutoEvaluation::BedrockOpenAIOssInvoke::MODEL,
        llm_prompt_tokens: 25,
        llm_completion_tokens: 35,
        llm_cached_tokens: nil,
      }
      expected_metrics = {
        statements: shared_expected_metrics_attributes,
        verdicts: shared_expected_metrics_attributes,
        reason: shared_expected_metrics_attributes,
      }
      expect(result)
        .to be_a(AutoEvaluation::ScoreResult)
        .and have_attributes(
          score: 0.5,
          reason:,
          success: true,
          llm_responses: expected_llm_responses,
          metrics: expected_metrics,
        )
    end

    context "when the answer has a rephrased question" do
      let(:question_message) { "This is a rephrased test question." }
      let(:answer) { build(:answer, message: answer_message, rephrased_question: question_message) }

      it "uses the rephrased question in the prompt" do
        result = described_class.call(answer)
        expect(result.reason).to eq(reason)
      end
    end

    context "when 'idk' verdicts are present" do
      let(:verdicts) do
        [
          { "verdict" => "idk", "reason" => "Cannot determine relevance." },
          { "verdict" => "no", "reason" => "The statement is irrelevant." },
        ]
      end

      it "treats 'idk' verdicts as positive in the score" do
        result = described_class.call(answer)

        expect(result.score).to eq(0.5)
      end
    end

    context "when no statements are extracted from the answer" do
      let(:statements_json) { { statements: [] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No statements were extracted from the answer.",
            success: true,
            llm_responses: hash_including(statements: anything),
            metrics: hash_including(statements: anything),
          )
      end
    end

    context "when no verdicts are generated for the extracted statements" do
      let(:verdicts_json) { { verdicts: [] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time)
                    .and_return(200.0, 202.0, 204.0, 206.0)

        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No verdicts were generated for the extracted statements.",
            success: true,
            llm_responses: hash_including(
              statements: anything,
              verdicts: anything,
            ),
            metrics: hash_including(
              statements: anything,
              verdicts: anything,
            ),
          )
      end
    end

    context "when verdicts are generated and none have a 'no' verdict" do
      let(:verdicts_json) { { verdicts: [{ "verdict" => "yes" }, { "verdict" => "yes" }] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0, 204.0, 206.0)

        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "The response fully addressed the input with no irrelevant statements.",
            success: true,
            llm_responses: hash_including(
              statements: anything,
              verdicts: anything,
            ),
            metrics: hash_including(
              statements: anything,
              verdicts: anything,
            ),
          )
      end
    end
  end
end
