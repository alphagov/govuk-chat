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

    AnswerAnalysis.enqueue_async_analysis(answer) if answer.persisted?
  end
end
