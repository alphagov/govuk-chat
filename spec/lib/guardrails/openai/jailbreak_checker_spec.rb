RSpec.describe Guardrails::OpenAI::JailbreakChecker do # rubocop:disable RSpec/SpecFilePathFormat
  let(:input) { "User question" }

  describe ".call" do
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
        answer: Guardrails::JailbreakChecker.pass_value,
        chat_options: { model: described_class::OPENAI_MODEL },
      )

      described_class.call(input)
      expect(openai_request).to have_been_made
    end
  end
end
