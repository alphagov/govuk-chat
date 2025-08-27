class AnswerTopicsJob < ApplicationJob
  MAX_RETRIES = 5
  retry_on Anthropic::Errors::APIError, wait: 1.minute, attempts: MAX_RETRIES

  def perform(answer_id)
    answer = Answer.includes(:analysis, question: :conversation).find_by(id: answer_id)

    return logger.warn("No answer found for #{answer_id}") unless answer
    return logger.warn("Answer #{answer_id} has already been tagged with topics") if answer.analysis&.primary_topic.present?
    unless answer.eligible_for_topic_analysis?
      return logger.info("Answer #{answer_id} is not eligible for topic analysis")
    end

    if Rails.configuration.answer_strategy == "non_llm_answer"
      # Temporary strategy for SREs to load test without incurring LLM costs
      sleep 10
      analysis = answer.build_analysis
      analysis.primary_topic = "non_llm_primary_topic"
      analysis.secondary_topic = "non_llm_secondary_topic"
      analysis.save!
    else
      result = AnswerAnalysisGeneration::TopicTagger.call(answer.rephrased_question || answer.question.message)
      analysis = answer.build_analysis(
        primary_topic: result.primary_topic,
        secondary_topic: result.secondary_topic,
      )
      analysis.assign_metrics("topic_tagger", result.metrics)
      analysis.assign_llm_response("topic_tagger", result.llm_response)
      analysis.save!
    end
  end
end
