RSpec.describe AnswerComposition::Pipeline::OutputGuardrails do
  let(:context) { build(:answer_pipeline_context) }
  let(:answer_message) { "sample answer message" }

  before do
    context.answer.message = answer_message
    allow(OutputGuardrails::FewShot).to receive(:call).and_return(few_shot_response)
  end

  context "when the guardrails are not triggered" do
    let(:few_shot_response) do
      OutputGuardrails::FewShot::Result.new(
        triggered: false,
        guardrails: [],
        llm_guardrail_result: "False | None",
        llm_response: {
          "message": {
            "role": "assistant",
            "content": "False | None",
          },
          "finish_reason": "stop",
        },
        llm_token_usage: { "prompt_tokens" => 13, "completion_tokens" => 7 },
      )
    end

    it "calls the guardrails with the answer message" do
      described_class.call(context)
      expect(OutputGuardrails::FewShot).to have_received(:call).with(context.answer.message)
    end

    it "does not abort the pipeline" do
      expect { described_class.call(context) }.not_to change(context, :aborted?).from(false)
    end

    it "does not change the message" do
      expect { described_class.call(context) }.not_to change(context.answer, :message)
    end

    it "sets the output_guardrail_status" do
      expect { described_class.call(context) }.to change(context.answer, :output_guardrail_status).to("pass")
    end

    it "assigns the llm response to the answer" do
      described_class.call(context)

      expect(context.answer.llm_responses["output_guardrails"]).to eq(few_shot_response.llm_response)
    end

    it "assigns metrics to the answer" do
      allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["output_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
      })
    end
  end

  context "when the guardrails are triggered" do
    let(:few_shot_response) do
      OutputGuardrails::FewShot::Result.new(
        triggered: true,
        guardrails: %w[political],
        llm_guardrail_result: 'True | "3"',
        llm_response: {
          "message": {
            "role": "assistant",
            "content": 'True | "3"',
          },
          "finish_reason": "stop",
        },
        llm_token_usage: { "prompt_tokens" => 13, "completion_tokens" => 7 },
      )
    end

    it "aborts the pipeline and updates the answer's status and message attributes" do
      expect {
        described_class.call(context)
      }.to throw_symbol(:abort)

      expect(context.answer).to have_attributes(
        status: "abort_output_guardrails",
        message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
        output_guardrail_status: "fail",
        output_guardrail_failures: %w[political],
      )
    end

    it "assigns the llm response to the answer" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer.llm_responses["output_guardrails"]).to eq(few_shot_response.llm_response)
    end

    it "assigns metrics to the answer" do
      allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["output_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
      })
    end
  end

  context "when a FewShot::ResponseError occurs during the FewShot call" do
    let(:few_shot_response) { nil }

    before do
      allow(OutputGuardrails::FewShot).to receive(:call)
        .and_raise(OutputGuardrails::FewShot::ResponseError.new("An error occurred", 'False | "1, 2"', { "prompt_tokens" => 13, "completion_tokens" => 7 }))
    end

    it "aborts the pipeline and updates the answer's status with an error message" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer).to have_attributes(
        status: "error_output_guardrails",
        message: Answer::CannedResponses::GUARDRAILS_FAILED_MESSAGE,
        output_guardrail_status: "error",
      )
    end

    it "assigns the llm response to the answer" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer.llm_responses["output_guardrails"]).to eq('False | "1, 2"')
    end

    it "assigns metrics to the answer" do
      allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["output_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
      })
    end
  end
end
