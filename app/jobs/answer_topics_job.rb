class AnswerTopicsJob < ApplicationJob
  MAX_RETRIES = 5
  queue_as :default
  retry_on Anthropic::Errors::APIError, wait: 1.minute, attempts: MAX_RETRIES

  def perform(answer_id)
    answer = Answer.includes(:analysis, question: :conversation).find_by(id: answer_id)

    return logger.warn("No answer found for #{answer_id}") unless answer
    return logger.warn("Answer #{answer_id} has already been tagged with topics") if answer.analysis&.primary_topic.present?

    AnswerAnalysisGeneration::TopicTagger.call(answer)
  end
end
