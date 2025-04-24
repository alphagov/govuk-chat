class Api::V0::ConversationsController < ApplicationController
  before_action { authorise_user!(SignonUser::Permissions::CONVERSATION_API) }

  def show
    conversation = Conversation.includes(questions: { answer: %i[sources feedback] })
                               .find(params[:conversation_id])
    answered_questions = conversation.questions.joins(:answer)
    pending_question = conversation.questions.unanswered.last

    render(
      json: ConversationBlueprint.render(conversation, answered_questions:, pending_question:),
      status: :ok,
    )
  end

  def answer
    conversation = Conversation.includes(questions: { answer: %i[sources feedback] })
                               .find(params[:conversation_id])
    question = conversation.questions.find(params[:question_id])
    answer = question.answer

    if answer.present?
      render json: AnswerBlueprint.render(answer), status: :ok
    else
      render json: {}, status: :accepted
    end
  end
end
