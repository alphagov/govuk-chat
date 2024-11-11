RSpec.describe AnswerComposition::Pipeline::AnswerGuardrails do
  let(:context) { build(:answer_pipeline_context) }
  let(:message) { "sample answer message" }

  before do
    context.answer.message = message
    allow(Guardrails::MultipleChecker).to receive(:call).and_return(guardrail_response)
  end

  context "when the guardrails are not triggered" do
    let(:guardrail_response) { build(:guardrails_multiple_checker_result, :pass) }

    it_behaves_like "a passing guardrail pipeline step", "answer_guardrails"

    it "does not abort the pipeline" do
      described_class.call(context)
      expect(context.aborted?).to be false
    end
  end

  context "when the guardrails are triggered" do
    let(:guardrail_response) { build(:guardrails_multiple_checker_result, :fail) }

    it "aborts the pipeline and updates the answer's status and message attributes" do
      expect {
        described_class.call(context)
      }.to throw_symbol(:abort)

      expect(context.answer).to have_attributes(
        status: "abort_answer_guardrails",
        message: Answer::CannedResponses::ANSWER_GUARDRAILS_FAILED_MESSAGE,
        answer_guardrails_status: "fail",
        answer_guardrails_failures: %w[political],
      )
    end

    it "assigns the llm response to the answer" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer.llm_responses["answer_guardrails"]).to eq(guardrail_response.llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["answer_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
        llm_cached_tokens: 10,
      })
    end
  end

  it_behaves_like "an erroring guardrail pipeline step", "answer_guardrails", Answer::CannedResponses::ANSWER_GUARDRAILS_FAILED_MESSAGE
end
