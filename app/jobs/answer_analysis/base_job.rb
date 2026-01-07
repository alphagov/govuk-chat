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
  end
end
