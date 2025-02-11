module AnswerComposition::Pipeline::Claude
  def self.prompt_config
    Rails.configuration.govuk_chat_private.llm_prompts.claude
  end
end
