RSpec.describe AnswerComposition::Pipeline::QuestionRoutingGuardrails do
  let(:context) { build(:answer_pipeline_context) }
  let(:message) { "sample answer message" }

  before do
    context.answer.message = message
    allow(Guardrails::MultipleChecker).to receive(:call).and_return(guardrail_response)
  end

  context "when the guardrails are not triggered" do
    let(:guardrail_response) { build(:guardrails_multiple_checker_result, :pass) }

    it_behaves_like "a passing guardrail pipeline step", "question_routing_guardrails"

    it "does nothing if the question routing label is 'geniune_rag'" do
      expect(Guardrails::MultipleChecker).not_to receive(:call)

      context.answer.question_routing_label = "genuine_rag"

      described_class.call(context)
    end

    it "aborts the pipeline" do
      described_class.call(context)
      expect(context.aborted?).to be true
    end
  end

  context "when the guardrails are triggered" do
    let(:guardrail_response) { build(:guardrails_multiple_checker_result, :fail) }

    it "sets the message on the answer" do
      described_class.call(context)

      expect(context.answer).to have_attributes({
        message: Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE,
        status: "abort_question_routing_guardrails",
        question_routing_guardrails_failures: %w[political],
      })
    end

    it "aborts the pipeline and assigns the right attributes" do
      described_class.call(context)

      expect(context.aborted?).to be true
      expect(context.answer.question_routing_guardrails_status).to eq("fail")
    end
  end

  it_behaves_like "an erroring guardrail pipeline step", "question_routing_guardrails", Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE
end
