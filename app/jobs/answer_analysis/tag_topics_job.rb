module AnswerAnalysis
  class TagTopicsJob < ApplicationJob
    MAX_RETRIES = 5
    retry_on Anthropic::Errors::APIError, wait: 1.minute, attempts: MAX_RETRIES

    def perform(answer_id)
      answer = Answer.includes(:topics, question: :conversation).find_by(id: answer_id)

      return logger.warn("No answer found for #{answer_id}") unless answer
      return logger.warn("Answer #{answer_id} has already been tagged with topics") if answer.topics.present?
      unless answer.eligible_for_topic_analysis?
        return logger.info("Answer #{answer_id} is not eligible for topic analysis")
      end

      result = AutoEvaluation::TopicTagger.call(answer.question_used)

      topics = answer.build_topics(
        primary_topic: result.primary_topic,
        secondary_topic: result.secondary_topic,
      )
      topics.assign_metrics("topic_tagger", result.metrics)
      topics.assign_llm_response("topic_tagger", result.llm_response)

      topics.save!
    end
  end
end
