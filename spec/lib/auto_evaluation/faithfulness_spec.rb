RSpec.describe AutoEvaluation::Faithfulness, :aws_credentials_stubbed do
  describe ".call" do
    let(:prompts) { AutoEvaluation::Prompts.config.faithfulness }
    let(:answer_message) { "Einstein won the Nobel Prize in 1968 for the photoelectric effect." }
    let(:retrieval_context) { "Einstein won the Nobel Prize in 1921 for the photoelectric effect." }

    let(:truths) { ["Einstein won the Nobel Prize in 1921.", "Einstein won the Nobel Prize for the photoelectric effect."] }
    let(:truths_json) { { truths: }.to_json }
    let(:user_prompt_truths) do
      sprintf(
        prompts.fetch(:truths).fetch(:user_prompt),
        retrieval_context:,
      )
    end
    let(:truths_tools) { [prompts.fetch(:truths).fetch(:tool_spec)] }
    let!(:truths_stub) do
      bedrock_invoke_model_openai_oss_tool_call(
        user_prompt_truths,
        truths_tools,
        truths_json,
      )
    end

    let(:claims) { ["Einstein won the Nobel Prize in 1968.", "Einstein won the Nobel Prize for the photoelectric effect."] }
    let(:claims_json) { { claims: }.to_json }
    let(:user_prompt_claims) do
      sprintf(
        prompts.fetch(:claims).fetch(:user_prompt),
        answer: answer_message,
      )
    end
    let(:claims_tools) { [prompts.fetch(:claims).fetch(:tool_spec)] }
    let!(:claims_stub) do
      bedrock_invoke_model_openai_oss_tool_call(
        user_prompt_claims,
        claims_tools,
        claims_json,
      )
    end

    let(:verdicts) do
      [
        { "verdict" => "no", "reason" => "The retrieval context states Einstein won in 1921, not 1968." },
        { "verdict" => "yes" },
      ]
    end
    let(:verdicts_json) { { verdicts: }.to_json }
    let(:user_prompt_verdicts) do
      sprintf(
        prompts.fetch(:verdicts).fetch(:user_prompt),
        claims:,
        retrieval_context: truths.join("\n\n"),
      )
    end
    let(:verdicts_tools) { [prompts.fetch(:verdicts).fetch(:tool_spec)] }
    let!(:verdicts_stub) do
      bedrock_invoke_model_openai_oss_tool_call(
        user_prompt_verdicts,
        verdicts_tools,
        verdicts_json,
      )
    end

    let(:reason) { "The score is 0.5 because the answer incorrectly stated the year Einstein won the Nobel Prize." }
    let(:reason_json) { { reason: }.to_json }
    let(:user_prompt_reason) do
      sprintf(
        prompts.fetch(:reason).fetch(:user_prompt),
        score: "0.50",
        contradictions: ["The retrieval context states Einstein won in 1921, not 1968."],
      )
    end
    let(:reason_tools) { [prompts.fetch(:reason).fetch(:tool_spec)] }
    let!(:reason_stub) do
      bedrock_invoke_model_openai_oss_tool_call(
        user_prompt_reason,
        reason_tools,
        reason_json,
      )
    end

    it "returns a results object with the expected attributes" do
      allow(Clock).to receive(:monotonic_time)
                  .and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0, 212.0, 214.0)

      result = described_class.call(
        answer_message:,
        retrieval_context:,
      )

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
        .to be_a(AutoEvaluation::Result)
        .and have_attributes(
          score: 0.5,
          reason:,
          success: true,
          llm_responses: expected_llm_responses,
          metrics: expected_metrics,
        )
    end

    context "when 'idk' verdicts are present" do
      let(:verdicts) do
        [
          { "verdict" => "idk", "reason" => "Cannot determine if correct." },
          { "verdict" => "no", "reason" => "The retrieval context states Einstein won in 1921, not 1968." },
        ]
      end

      it "treats 'idk' verdicts as positive in the score" do
        result = described_class.call(
          answer_message:,
          retrieval_context:,
        )

        expect(result.score).to eq(0.5)
      end
    end

    context "when no claims are extracted from the answer" do
      let(:claims_json) { { claims: [] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0, 204.0, 206.0)

        result = described_class.call(
          answer_message:,
          retrieval_context:,
        )

        expect(result)
          .to be_a(AutoEvaluation::Result)
          .and have_attributes(
            score: 1.0,
            reason: "No claims were extracted from the answer.",
            success: true,
            llm_responses: hash_including(truths: anything, claims: anything),
            metrics: hash_including(truths: anything, claims: anything),
          )
      end
    end

    context "when no truths are extracted from the retrieval context" do
      let(:truths_json) { { truths: [] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0, 204.0, 206.0)

        result = described_class.call(
          answer_message:,
          retrieval_context:,
        )

        expect(result)
          .to be_a(AutoEvaluation::Result)
          .and have_attributes(
            score: 1.0,
            reason: "No truths were extracted from the retrieval context.",
            success: true,
            llm_responses: hash_including(truths: anything, claims: anything),
            metrics: hash_including(truths: anything, claims: anything),
          )
      end
    end

    context "when no verdicts are generated for the extracted claims" do
      let(:verdicts_json) { { verdicts: [] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time)
                    .and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0)

        result = described_class.call(
          answer_message:,
          retrieval_context:,
        )

        expect(result)
          .to be_a(AutoEvaluation::Result)
          .and have_attributes(
            score: 1.0,
            reason: "No verdicts were generated for the extracted claims.",
            success: true,
            llm_responses: hash_including(
              truths: anything,
              claims: anything,
              verdicts: anything,
            ),
            metrics: hash_including(
              truths: anything,
              claims: anything,
              verdicts: anything,
            ),
          )
      end
    end

    context "when verdicts are generated and none have a 'no' verdict" do
      let(:verdicts_json) { { verdicts: [{ "verdict" => "yes" }, { "verdict" => "yes" }] }.to_json }

      it "returns a result object with the expected attributes" do
        allow(Clock).to receive(:monotonic_time).and_return(200.0, 202.0, 204.0, 206.0, 208.0, 210.0)

        result = described_class.call(
          answer_message:,
          retrieval_context:,
        )

        expect(result)
          .to be_a(AutoEvaluation::Result)
          .and have_attributes(
            score: 1.0,
            reason: "All claims in the response are supported by the retrieval context.",
            success: true,
            llm_responses: hash_including(
              truths: anything,
              claims: anything,
              verdicts: anything,
            ),
            metrics: hash_including(
              truths: anything,
              claims: anything,
              verdicts: anything,
            ),
          )
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
      let(:user_prompt_reason) do
        sprintf(
          prompts.fetch(:reason).fetch(:user_prompt),
          score: "0.33",
          contradictions: ["Contradiction 1", "Contradiction 2"],
        )
      end

      it "returns success: false" do
        result = described_class.call(
          answer_message:,
          retrieval_context:,
        )

        expect(result.success).to be false
        expect(result.score).to be_within(0.01).of(0.33)
      end
    end
  end
end
