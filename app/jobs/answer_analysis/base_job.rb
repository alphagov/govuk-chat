module AnswerAnalysis
  class BaseJob < ApplicationJob
    NUMBER_OF_RUNS = 3
    MAX_RETRIES = 5
    retry_on Aws::Errors::ServiceError, wait: 1.minute, attempts: MAX_RETRIES

  private

    def eligible_for_answer_analysis?(answer_id)
      eligible = Answer.status_answered.exists?(id: answer_id)

      unless eligible
        logger.warn("Couldn't find an answer #{answer_id} that was eligible for auto-evaluation")
      end

      eligible
    end

    def quota_limit_reached?
      key = "auto_evaluations_count_#{Time.current.beginning_of_hour.to_i}"
      max_evaluations = Rails.configuration.max_auto_evaluations_per_hour
      # fallback to 1 in scenarios where we have a null cache (test environment) and this returns nil
      count = Rails.cache.increment(key, expires_in: 1.hour) || 1

      if count > max_evaluations
        logger.warn("Auto-evaluation quota limit of #{max_evaluations} evaluations per hour reached")
        return true
      end

      false
    end
  end
end
