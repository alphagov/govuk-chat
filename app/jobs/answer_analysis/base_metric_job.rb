module AnswerAnalysis
  class BaseMetricJob < ApplicationJob
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
      quota = Rails.configuration.max_auto_evaluation_metrics_per_hour
      current_count = Rails.cache.read("auto_evaluation_metrics_run_count")

      if current_count.nil?
        Rails.cache.write("auto_evaluation_metrics_run_count", 1, expires_in: 1.hour)
        return false
      end

      if current_count >= quota
        logger.warn("Auto-evaluation quota limit of #{quota} metrics per hour reached")
        return true
      end

      Rails.cache.increment("auto_evaluation_metrics_run_count")
      false
    end
  end
end
