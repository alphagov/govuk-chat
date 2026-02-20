module AnswerComposition::Pipeline::Claude
  def self.prompt_config(prompt_name, bedrock_model)
    prompts = Rails.configuration.govuk_chat_private.llm_prompts.claude.fetch(prompt_name) do
      raise "No LLM prompts found for #{prompt_name}"
    end

    prompts.fetch(bedrock_model.to_sym) do
      raise "No LLM prompts found for the #{bedrock_model} model in the #{prompt_name} prompt configuration"
    end
  end
end
