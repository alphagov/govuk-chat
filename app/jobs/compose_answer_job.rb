class ComposeAnswerJob < ApplicationJob
  queue_as :default

  def perform(question_id)
    question = Question.includes(:answer, conversation: :user).find_by(id: question_id)
    return logger.warn("No question found for #{question_id}") unless question
    return logger.warn("Question #{question_id} has already been answered") if question.answer

    answer = AnswerComposition::Composer.call(question)

    begin
      answer.save!
      user = answer.question.conversation.user

      if user.present? && answer.status_abort_jailbreak_guardrails?
        user.handle_jailbreak_attempt
      end
    rescue ActiveRecord::RecordNotUnique
      logger.warn("Already an answer created for #{question_id}")
    end
  end
end
