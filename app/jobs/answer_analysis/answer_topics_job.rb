module AnswerAnalysis
  class AnswerTopicsJob < BaseMetricJob
    retry_on Anthropic::Errors::APIError, wait: 1.minute, attempts: MAX_RETRIES

    def perform(answer_id)
      answer = Answer.includes(:topics, question: :conversation).find_by(id: answer_id)

      return logger.warn("No answer found for #{answer_id}") unless answer
      return logger.warn("Answer #{answer_id} has already been tagged with topics") if answer.topics.present?
      unless answer.eligible_for_topic_analysis?
        return logger.info("Answer #{answer_id} is not eligible for topic analysis")
      end
      return if quota_limit_reached?

      result = AutoEvaluation::TopicTagger.call(answer.rephrased_question || answer.question.message)
      topics = answer.build_topics(
        primary_topic: result.primary_topic,
        secondary_topic: result.secondary_topic,
        llm_response: result.llm_response,
        metrics: result.metrics,
      )
      topics.save!
    end
  end
end
