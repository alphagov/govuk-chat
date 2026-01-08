RSpec.describe AutoEvaluation::Faithfulness, :aws_credentials_stubbed do
  describe ".call" do
    let(:answer_message) { "Einstein won the Nobel Prize in 1968 for the photoelectric effect." }
    let(:retrieval_context) { "Einstein won the Nobel Prize in 1921 for the photoelectric effect." }
    let(:question) { build(:question, message: "When did Einstein win the Nobel Prize?") }
    let(:chunk) { build(:answer_source_chunk, plain_content: retrieval_context) }
    let(:used_source) { build(:answer_source, used: true, chunk:) }
    let(:answer) { build(:answer, question:, message: answer_message, sources: [used_source]) }

    let(:truths) { ["Einstein won the Nobel Prize in 1921.", "Einstein won the Nobel Prize for the photoelectric effect."] }
    let(:truths_json) { { truths: }.to_json }
    let(:claims) { ["Einstein won the Nobel Prize in 1968.", "Einstein won the Nobel Prize for the photoelectric effect."] }
    let(:claims_json) { { claims: }.to_json }
    let(:verdicts) do
      [
        { "verdict" => "no", "reason" => "The retrieval context states Einstein won in 1921, not 1968." },
        { "verdict" => "yes" },
      ]
    end
    let(:verdicts_json) { { verdicts: }.to_json }
    let(:reason) { "The score is 0.5 because the answer incorrectly stated the year Einstein won the Nobel Prize." }
    let(:reason_json) { { reason: }.to_json }

    let!(:faithfulness_stubs) do
      stub_bedrock_invoke_model_openai_oss_faithfulness(
        retrieval_context:,
        answer_message:,
        truths_json:,
        claims_json:,
        verdicts_json:,
        reason_json:,
      )
    end
    let(:truths_stub) { faithfulness_stubs[:truths] }
    let(:claims_stub) { faithfulness_stubs[:claims] }
    let(:verdicts_stub) { faithfulness_stubs[:verdicts] }
    let(:reason_stub) { faithfulness_stubs[:reason] }

    it "returns a results object with the expected attributes" do
      allow(Clock).to receive(:monotonic_time)
                  .and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0, 212.0, 214.0)

      result = described_class.call(answer)

      expected_llm_responses = {
        truths: JSON.parse(truths_stub.response.body),
        claims: JSON.parse(claims_stub.response.body),
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
        truths: shared_expected_metrics_attributes,
        claims: shared_expected_metrics_attributes,
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

    context "when 'idk' verdicts are present alongside 'no' verdicts" do
      let(:verdicts) do
        [
          { "verdict" => "idk", "reason" => "Cannot determine if correct." },
          { "verdict" => "no", "reason" => "The retrieval context states Einstein won in 1921, not 1968." },
        ]
      end

      it "treats 'idk' verdicts as faithful (not contradictions)" do
        result = described_class.call(answer)

        expect(result.score).to eq(0.5)
      end
    end

    context "when no truths are extracted from the retrieval context" do
      let(:truths_json) { { truths: [] }.to_json }

      it "returns early with score 1.0 and skips claims, verdicts and reason LLM calls" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0)

        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No truths were extracted from the retrieval context.",
            success: true,
          )
        expect(result.llm_responses.keys).to contain_exactly(:truths)
        expect(result.metrics.keys).to contain_exactly(:truths)
      end
    end

    context "when no claims are extracted from the answer" do
      let(:claims_json) { { claims: [] }.to_json }

      it "returns early with score 1.0 and skips verdicts and reason LLM calls" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0, 204.0, 206.0)

        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "No claims were extracted from the answer.",
            success: true,
          )
        expect(result.llm_responses.keys).to contain_exactly(:truths, :claims)
        expect(result.metrics.keys).to contain_exactly(:truths, :claims)
      end
    end

    context "when all verdicts are faithful (no 'no' verdicts)" do
      let(:verdicts_json) { { verdicts: [{ "verdict" => "yes" }, { "verdict" => "idk" }] }.to_json }

      it "returns early with score 1.0 and skips reason LLM call" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0)

        result = described_class.call(answer)

        expect(result)
          .to be_a(AutoEvaluation::ScoreResult)
          .and have_attributes(
            score: 1.0,
            reason: "The response is fully supported by the retrieval context.",
            success: true,
          )
        expect(result.llm_responses.keys).to contain_exactly(:truths, :claims, :verdicts)
        expect(result.metrics.keys).to contain_exactly(:truths, :claims, :verdicts)
      end
    end

    context "when score is below threshold" do
      let(:verdicts) do
        [
          { "verdict" => "no", "reason" => "Contradiction 1" },
          { "verdict" => "no", "reason" => "Contradiction 2" },
          { "verdict" => "yes" },
        ]
      end

      it "returns success: false" do
        result = described_class.call(answer)

        expect(result.success).to be false
        expect(result.score).to be_within(0.01).of(0.33)
      end
    end
  end
end
