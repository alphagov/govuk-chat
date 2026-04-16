module AnswerComposition::Pipeline::Prompts
  def self.config(component_name, bedrock_model)
    prompts = Rails.configuration.govuk_chat_private.llm_prompts.answer_composition.fetch(component_name.to_sym) do
      raise "No LLM prompts found for #{component_name}"
    end

    prompts.fetch(bedrock_model.to_sym) do
      raise "No LLM prompts found for the #{bedrock_model} model in the #{component_name} prompt configuration"
    end
  end
end
