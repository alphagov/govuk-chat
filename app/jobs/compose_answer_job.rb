class ComposeAnswerJob < ApplicationJob
  queue_as :answer

  def perform(question_id)
    question = Question.includes(:answer, :conversation).find_by(id: question_id)
    return logger.warn("No question found for #{question_id}") unless question
    return logger.warn("Question #{question_id} has already been answered") if question.answer

    answer = AnswerComposition::Composer.call(question)

    begin
      answer.save!
    rescue ActiveRecord::RecordNotUnique
      logger.warn("Already an answer created for #{question_id}")
    end

    if answer.persisted?
      # TODO: Once we've added a few metrics we should move these to a single job that
      # kicks off all analysis jobs.
      AnswerAnalysis::TagTopicsJob.perform_later(answer.id)
      AnswerAnalysis::AnswerRelevancyJob.perform_later(answer.id)
    end
  end
end
