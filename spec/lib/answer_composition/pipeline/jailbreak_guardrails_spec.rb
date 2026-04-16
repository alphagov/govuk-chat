RSpec.describe AnswerComposition::Pipeline::JailbreakGuardrails, :aws_credentials_stubbed do
  let(:context) { build(:answer_pipeline_context) }
  let(:input) { context.question.message }
  let!(:stub) { stub_claude_jailbreak_guardrails(input) }
  let(:pass_value) { "PassValue" }

  it_behaves_like "a claude answer composition component with a configurable model", "BEDROCK_CLAUDE_JAILBREAK_GUARDRAILS_MODEL" do
    let(:pipeline_step) { described_class.new(context) }
    let(:stubbed_request_lambda) do
      lambda { |bedrock_model|
        stub_claude_jailbreak_guardrails(
          input,
          chat_options: { bedrock_model: },
        )
      }
    end
  end

  it "uses an overridden AWS region if set" do
    ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
      allow(Anthropic::BedrockClient).to receive(:new).and_call_original

      described_class.call(context)

      expect(Anthropic::BedrockClient)
        .to have_received(:new).with(hash_including(aws_region: "my-region"))
      expect(stub).to have_been_requested
    end
  end

  context "when the guardrails are not triggered" do
    it "does not change the message" do
      expect { described_class.call(context) }.not_to change(context.answer, :message)
    end

    it "sets the jailbreak_guardrails_status" do
      expect { described_class.call(context) }.to change(context.answer, :jailbreak_guardrails_status).to("pass")
    end

    it "assigns the llm response to the answer" do
      described_class.call(context)

      expected_llm_response = claude_messages_response(
        content: [claude_messages_text_block(pass_value)],
      ).to_h
      expect(context.answer.llm_responses["jailbreak_guardrails"]).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      stub_claude_jailbreak_guardrails(input)

      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["jailbreak_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 10,
        llm_completion_tokens: 20,
        llm_cached_tokens: nil,
        model: BedrockModels.model_id(described_class::DEFAULT_MODEL),
      })
    end
  end

  context "when the guardrails are triggered" do
    let!(:stub) { stub_claude_jailbreak_guardrails(input, "FailValue") }
    let(:fail_value) { "FailValue" }

    it "aborts the pipeline and updates the answer's status and message attributes" do
      expect {
        described_class.call(context)
      }.to throw_symbol(:abort)

      expect(context.answer).to have_attributes(
        status: "guardrails_jailbreak",
        message: Answer::CannedResponses::JAILBREAK_GUARDRAILS_FAILED_MESSAGE,
        jailbreak_guardrails_status: "fail",
      )
    end

    it "assigns the llm response to the answer" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expected_llm_response = claude_messages_response(
        content: [claude_messages_text_block(fail_value)],
      ).to_h
      expect(context.answer.llm_responses["jailbreak_guardrails"]).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["jailbreak_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 10,
        llm_completion_tokens: 20,
        llm_cached_tokens: nil,
        model: BedrockModels.model_id(described_class::DEFAULT_MODEL),
      })
    end
  end

  context "when the LLM response is in an unexpected format" do
    let(:response) { "UnexpectedFormat" }
    let!(:stub) { stub_claude_jailbreak_guardrails(input, response) }

    it "aborts the pipeline and updates the answer's status and message attributes" do
      expect {
        described_class.call(context)
      }.to throw_symbol(:abort)

      expect(context.answer).to have_attributes(
        status: "error_jailbreak_guardrails",
        jailbreak_guardrails_status: "error",
        message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
      )
    end

    it "assigns the llm response to the answer" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
      expected_llm_response = claude_messages_response(
        content: [claude_messages_text_block(response)],
      ).to_h
      expect(context.answer.llm_responses["jailbreak_guardrails"]).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["jailbreak_guardrails"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 10,
        llm_completion_tokens: 20,
        llm_cached_tokens: nil,
        model: BedrockModels.model_id(described_class::DEFAULT_MODEL),
      })
    end
  end
end
