class AutoEvaluation::AnswerRelevancy::StatementGenerator
  def self.call(...) = new(...).call

  def initialize(answer_message:)
    @answer_message = answer_message
  end

  def call
    result = AutoEvaluation::BedrockConverseAutoEvaluation.call(user_prompt)
    [result.evaluation_data.fetch("statements"), result.llm_response, result.metrics]
  end

private

  attr_reader :answer_message

  def llm_prompts
    Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
  end

  def user_prompt
    sprintf(
      llm_prompts.fetch(:statements).fetch(:user_prompt),
      answer: answer_message,
    )
  end
end
