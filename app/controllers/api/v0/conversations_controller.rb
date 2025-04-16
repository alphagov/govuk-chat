class Api::V0::ConversationsController < ApplicationController
  before_action :find_conversation
  before_action :find_question

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
