RSpec.describe AnswerComposition::Pipeline::Claude do
  describe ".prompt_config" do
    it "fetches the prompt configuration for the given component name and model" do
      config = {
        system_prompt: "The system prompt",
        user_prompt: "The user prompt ",
      }
      allow(Rails.configuration.govuk_chat_private.llm_prompts.claude).to receive(:fetch).with(:test_prompt).and_return({ claude_sonnet_4_0: config })

      result = described_class.prompt_config(:test_prompt, :claude_sonnet_4_0)

      expect(result).to eq(config)
    end

    it "raises an error if no prompt configuration is found for the given component name" do
      expect { described_class.prompt_config(:non_existent_component, :claude_sonnet_4_0) }
        .to raise_error("No LLM prompts found for non_existent_component")
    end

    it "raises an error if no prompt configuration is found for the given model" do
      allow(Rails.configuration.govuk_chat_private.llm_prompts.claude).to receive(:fetch).with(:test_prompt).and_return({ claude_sonnet_4_0: {} })

      expect { described_class.prompt_config(:test_prompt, :non_existent_model) }
      .to raise_error("No LLM prompts found for the non_existent_model model in the test_prompt prompt configuration")
    end
  end
end
