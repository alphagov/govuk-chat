class AutoEvaluation::AnswerRelevancy::ReasonGenerator
  def self.call(...) = new(...).call

  def initialize(question_message:, verdicts:, score:)
    @question_message = question_message
    @verdicts = verdicts
    @score = score
  end

  def call
    result = AutoEvaluation::BedrockConverseAutoEvaluation.call(user_prompt)
    [result.evaluation_data.fetch("reason"), result.llm_response, result.metrics]
  end

private

  attr_reader :question_message, :verdicts, :score

  def llm_prompts
    Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
  end

  def user_prompt
    sprintf(
      llm_prompts.fetch(:reason).fetch(:user_prompt),
      score:,
      unsuccessful_verdicts_reasons:,
      question: question_message,
    )
  end

  def unsuccessful_verdicts_reasons
    verdicts.select { |verdict| verdict["verdict"].strip.downcase == "no" }
            .map { |verdict| verdict["reason"] }
  end
end
