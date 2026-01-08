class AnswerAnalysisJob < ApplicationJob
  def perform(answer_id)
    AnswerAnalysis::TagTopicsJob.perform_later(answer_id)
    AnswerAnalysis::AnswerRelevancyJob.perform_later(answer_id)
  end
end
