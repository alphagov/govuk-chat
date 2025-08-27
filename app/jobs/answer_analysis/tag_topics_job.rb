module AnswerAnalysis
  class TagTopicsJob < BaseJob
    retry_on Anthropic::Errors::APIError, wait: 1.minute, attempts: MAX_RETRIES

    def perform(answer_id)
      answer = Answer.includes(:topics, question: :conversation).find_by(id: answer_id)

      return logger.warn("No answer found for #{answer_id}") unless answer
      return logger.warn("Answer #{answer_id} has already been tagged with topics") if answer.topics.present?
      unless answer.eligible_for_topic_analysis?
        return logger.info("Answer #{answer_id} is not eligible for topic analysis")
      end
      return if quota_limit_reached?

      if Rails.configuration.answer_strategy == "non_llm_answer"
        # Temporary strategy for SREs to load test without incurring LLM costs
        sleep 10
        topics = answer.build_topics(
          primary_topic: "business",
          secondary_topic: "benefits",
        )
      else
        result = AutoEvaluation::TopicTagger.call(answer.question_used)
        topics = answer.build_topics(
          primary_topic: result.primary_topic,
          secondary_topic: result.secondary_topic,
        )
        topics.assign_metrics("topic_tagger", result.metrics)
        topics.assign_llm_response("topic_tagger", result.llm_response)
      end

      topics.save!
    end
  end
end
