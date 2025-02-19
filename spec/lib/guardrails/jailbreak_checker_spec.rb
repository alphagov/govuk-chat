RSpec.describe Guardrails::JailbreakChecker do
  let(:input) { "User question" }

  it "calls OpenAI to check for jailbreak attempts" do
    prompts = Rails.configuration.govuk_chat_private.llm_prompts.openai.jailbreak_guardrails
    allow(prompts).to receive(:[]).and_call_original
    allow(prompts).to receive(:[]).with(:system_prompt).and_return("The system prompt")
    allow(prompts).to receive(:[]).with(:user_prompt).and_return("{input}")

    messages = array_including(
      { "role" => "system", "content" => "The system prompt" },
      { "role" => "user", "content" => input },
    )
    openai_request = stub_openai_chat_completion(
      messages,
      answer: described_class.pass_value,
      chat_options: { model: described_class::OPENAI_MODEL },
    )

    described_class.call(input)
    expect(openai_request).to have_been_made
  end

  it "returns a result object" do
    stub_openai_jailbreak_guardrails(input)

    result = described_class.call(input)
    expect(result)
      .to be_an_instance_of(described_class::Result)
      .and have_attributes(
        triggered: boolean,
        llm_response: hash_including("message", "finish_reason", "index"),
        llm_token_usage: hash_including("prompt_tokens", "completion_tokens", "total_tokens"),
      )
  end

  it "returns a result object with triggered true when guardrails fail" do
    stub_openai_jailbreak_guardrails(input, "FailValue")
    expect(described_class.call(input)).to have_attributes(triggered: true)
  end

  it "returns a result object with triggered false when guardrails pass" do
    stub_openai_jailbreak_guardrails(input, "PassValue")
    expect(described_class.call(input)).to have_attributes(triggered: false)
  end

  it "raises a response error when the LLM returns a different response" do
    stub_openai_jailbreak_guardrails(input, "?")
    expected_error = an_instance_of(described_class::ResponseError).and(
      having_attributes(
        message: "Error parsing jailbreak guardrails response",
        llm_guardrail_result: "?",
        llm_response: hash_including("message", "finish_reason", "index"),
        llm_token_usage: hash_including("prompt_tokens", "completion_tokens", "total_tokens"),
      ),
    )

    expect { described_class.call(input) }
      .to raise_error(expected_error)
  end
end
