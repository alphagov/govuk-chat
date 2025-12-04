class AutoEvaluation::AnswerRelevancy::VerdictsGenerator
  def self.call(...) = new(...).call

  def initialize(question_message:, statements:)
    @question_message = question_message
    @statements = statements
  end

  def call
    result = AutoEvaluation::BedrockConverseAutoEvaluation.call(user_prompt)
    [result.evaluation_data.fetch("verdicts"), result.llm_response, result.metrics]
  end

private

  attr_reader :question_message, :statements

  def llm_prompts
    Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
  end

  def user_prompt
    sprintf(
      llm_prompts.fetch(:verdicts).fetch(:user_prompt),
      question: question_message,
      statements:,
    )
  end
end
