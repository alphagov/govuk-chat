class AnswerInsightsJob < ApplicationJob
  queue_as :default

  def perform(answer_id)
    answer = Answer.includes(:analysis, question: :conversation).find_by(id: answer_id)
    return logger.warn("No answer found for #{answer_id}") unless answer

    AnswerInsights::TopicTagger.call(answer) if answer.can_have_tagged_topics?
  end
end
