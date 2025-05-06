RSpec.describe Guardrails::JailbreakChecker do
  let(:input) { "User question" }
  let(:pass_value) { "PassValue" }
  let(:fail_value) { "FailValue" }

  before do
    allow(described_class).to receive_messages(pass_value:, fail_value:)
  end

  it "calls the OpenAI jailbreak checker by default" do
    result = {
      llm_guardrail_result: pass_value,
      llm_response: {
        "message" => { "content" => pass_value },
        "finish_reason" => "stop",
        "index" => 0,
      },
      llm_token_usage: {
        "prompt_tokens" => 100,
        "completion_tokens" => 2,
        "total_tokens" => 102,
      },
    }

    allow(Guardrails::OpenAI::JailbreakChecker).to receive(:call).and_return(result)
    stub_openai_jailbreak_guardrails(input)

    described_class.call(input)
    expect(Guardrails::OpenAI::JailbreakChecker).to have_received(:call).with(input)
  end

  it "calls the Claude jailbreak checker when the provider is specified as :claude" do
    result = {
      llm_guardrail_result: pass_value,
      llm_response: {
        "message" => { "content" => pass_value },
        "finish_reason" => "stop",
        "index" => 0,
      },
      llm_token_usage: {
        "prompt_tokens" => 100,
        "completion_tokens" => 2,
        "total_tokens" => 102,
      },
    }

    allow(Guardrails::Claude::JailbreakChecker).to receive(:call).and_return(result)
    stub_openai_jailbreak_guardrails(input)

    described_class.call(input, :claude)
    expect(Guardrails::Claude::JailbreakChecker).to have_received(:call).with(input)
  end

  it "returns a result object" do
    stub_openai_jailbreak_guardrails(input)

    result = described_class.call(input)
    expect(result)
      .to be_an_instance_of(described_class::Result)
      .and have_attributes(
        triggered: boolean,
        llm_response: hash_including("message", "finish_reason", "index"),
        llm_prompt_tokens: be_a(Integer),
        llm_completion_tokens: be_a(Integer),
        llm_cached_tokens: be_a(Integer).or(be_nil),
      )
  end

  it "returns a result object with triggered true when guardrails fail" do
    stub_openai_jailbreak_guardrails(input, triggered: true)
    expect(described_class.call(input)).to have_attributes(triggered: true)
  end

  it "returns a result object with triggered false when guardrails pass" do
    stub_openai_jailbreak_guardrails(input, triggered: false)
    expect(described_class.call(input)).to have_attributes(triggered: false)
  end

  context "when the LLM returns a different response" do
    before do
      allow(Guardrails::OpenAI::JailbreakChecker).to receive(:call).and_return({
        llm_response: {
          "message" => { "content" => "unexpected" },
          "finish_reason" => "stop",
          "index" => 0,
        },
        llm_guardrail_result: "unexpected",
        llm_prompt_tokens: 10,
        llm_completion_tokens: 10,
        llm_cached_tokens: nil,
      })

      stub_openai_jailbreak_guardrails(input)
    end

    it "raises a response error when the LLM returns a different response" do
      expected_error = an_instance_of(described_class::ResponseError).and(
        having_attributes(
          message: "Error parsing jailbreak guardrails response",
          llm_guardrail_result: "unexpected",
          llm_response: hash_including("message", "finish_reason", "index"),
          llm_prompt_tokens: be_a(Integer),
          llm_completion_tokens: be_a(Integer),
          llm_cached_tokens: be_a(Integer).or(be_nil),
        ),
      )

      expect { described_class.call(input) }
        .to raise_error(expected_error)
    end

    it "raises an error that can be represented as JSON" do
      error = nil
      begin
        described_class.call(input)
      rescue described_class::ResponseError => e
        error = e
      end

      expect(error.as_json).to match({
        message: "Error parsing jailbreak guardrails response",
        llm_guardrail_result: "unexpected",
        llm_response: hash_including("message", "finish_reason", "index"),
        llm_prompt_tokens: be_a(Integer),
        llm_completion_tokens: be_a(Integer),
        llm_cached_tokens: be_a(Integer).or(be_nil),
      })
    end
  end
end
