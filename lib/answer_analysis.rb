module AnswerAnalysis
  def self.enqueue_async_analysis(answer)
    TagTopicsJob.perform_later(answer.id)
    AnswerRelevancyJob.perform_later(answer.id)
  end
end
