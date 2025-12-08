module AutoEvaluation::Prompts
  def self.config
    Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation
  end
end
