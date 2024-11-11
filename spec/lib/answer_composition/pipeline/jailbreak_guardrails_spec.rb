RSpec.describe AnswerComposition::Pipeline::JailbreakGuardrails do
  let(:context) { build(:answer_pipeline_context) }

  let(:llm_response) do
    {
      "index" => 0,
      "message" => {
        "role" => "assistant",
        "content" => "?",
      },
      "logprobs" => nil,
      "finish_reason" => "stop",
    }
  end

  let(:llm_token_usage) do
    { "prompt_tokens" => 10, "completion_tokens" => 5, "prompt_tokens_details" => { "cached_tokens" => 0 } }
  end

  context "when the guardrails are not triggered" do
    before do
      allow(Guardrails::JailbreakChecker)
        .to receive(:call)
        .and_return(Guardrails::JailbreakChecker::Result.new(triggered: false, llm_response:, llm_token_usage:))
    end

    it "calls the guardrails with the question message" do
      described_class.call(context)
      expect(Guardrails::JailbreakChecker).to have_received(:call).with(context.question.message)
    end

    it "does not abort the pipeline" do
      expect { described_class.call(context) }.not_to change(context, :aborted?).from(false)
    end

    it "does not change the message" do
      expect { described_class.call(context) }.not_to change(context.answer, :message)
    end

    it "sets the jailbreak_guardrails_status" do
      expect { described_class.call(context) }.to change(context.answer, :jailbreak_guardrails_status).to("pass")
    end

    it "assigns the llm response to the answer" do
      described_class.call(context)

      expect(context.answer.llm_responses["jailbreak_guardrails"]).to eq(llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["jailbreak_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 10,
        llm_completion_tokens: 5,
        llm_cached_tokens: 0,
      })
    end
  end

  context "when the guardrails are triggered" do
    before do
      allow(Guardrails::JailbreakChecker)
        .to receive(:call)
        .and_return(Guardrails::JailbreakChecker::Result.new(triggered: true, llm_response:, llm_token_usage:))
    end

    it "aborts the pipeline and updates the answer's status and message attributes" do
      expect {
        described_class.call(context)
      }.to throw_symbol(:abort)

      expect(context.answer).to have_attributes(
        status: "abort_jailbreak_guardrails",
        message: Answer::CannedResponses::JAILBREAK_GUARDRAILS_FAILED_MESSAGE,
        jailbreak_guardrails_status: "fail",
      )
    end

    it "assigns the llm response to the answer" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer.llm_responses["jailbreak_guardrails"]).to eq(llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["jailbreak_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 10,
        llm_completion_tokens: 5,
        llm_cached_tokens: 0,
      })
    end
  end

  context "when a Jailbreak::ResponseError occurs" do
    before do
      error = Guardrails::JailbreakChecker::ResponseError.new(
        "An error occurred",
        llm_guardrail_result: "?",
        llm_response:,
        llm_token_usage:,
      )
      allow(Guardrails::JailbreakChecker).to receive(:call).and_raise(error)
    end

    it "aborts the pipeline and updates the answer's status with an error message" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer).to have_attributes(
        status: "error_jailbreak_guardrails",
        message: Answer::CannedResponses::JAILBREAK_GUARDRAILS_FAILED_MESSAGE,
        jailbreak_guardrails_status: "error",
      )
    end

    it "assigns the llm response to the answer" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer.llm_responses["jailbreak_guardrails"]).to eq(llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["jailbreak_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 10,
        llm_completion_tokens: 5,
        llm_cached_tokens: 0,
      })
    end
  end
end
