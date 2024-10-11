RSpec.describe AnswerComposition::Pipeline::QuestionRoutingGuardrails do
  let(:context) { build(:answer_pipeline_context) }
  let(:answer_message) { "sample answer message" }
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

  before do
    context.answer.message = answer_message
    allow(OutputGuardrails::FewShot).to receive(:call).and_return(few_shot_response)
  end

  it "does nothing if the question routing label is 'geniune_rag'" do
    expect(OutputGuardrails::FewShot).not_to receive(:call)

    context.answer.question_routing_label = "genuine_rag"

    described_class.call(context)
  end

  it "assigns the llm response to the answer" do
    described_class.call(context)

    expect(context.answer.llm_responses["question_routing_guardrails"]).to eq(few_shot_response.llm_response)
  end

  it "aborts the pipeline and assigns the right attributes" do
    described_class.call(context)

    expect(context.aborted?).to be true
    expect(context.answer.question_routing_guardrails_status).to eq("pass")
  end

  it "assigns metrics to the answer when aborting" do
    allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

    described_class.call(context)

    expect(context.answer.metrics["question_routing_guardrails"]).to eq({
      duration: 1.5,
      llm_prompt_tokens: 13,
      llm_completion_tokens: 7,
    })
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

    it "sets the right attributes on the answer" do
      described_class.call(context)

      expect(context.answer).to have_attributes({
        message: Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE,
        status: "abort_output_guardrails",
        question_routing_guardrails_failures: %w[political],
      })
    end

    it "aborts the pipeline and assigns the right attributes" do
      described_class.call(context)

      expect(context.aborted?).to be true
      expect(context.answer.question_routing_guardrails_status).to eq("fail")
    end
  end

  context "when a FewShot::ResponseError occurs during the FewShot call" do
    let(:few_shot_response) { nil }

    before do
      allow(OutputGuardrails::FewShot)
        .to receive(:call)
        .and_raise(
          OutputGuardrails::FewShot::ResponseError.new(
            "An error occurred", 'False | "1, 2"',
            { "prompt_tokens" => 13, "completion_tokens" => 7 }
          ),
        )
    end

    it "aborts the pipeline and updates the answer's status with an error message" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expect(context.answer).to have_attributes(
        message: Answer::CannedResponses::QUESTION_ROUTING_GUARDRAILS_FAILED_MESSAGE,
        status: "error_output_guardrails",
        question_routing_guardrails_status: "error",
        llm_responses: a_hash_including("question_routing_guardrails" => 'False | "1, 2"'),
      )
    end

    it "assigns metrics to the answer" do
      allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["question_routing_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
      })
    end
  end
end
