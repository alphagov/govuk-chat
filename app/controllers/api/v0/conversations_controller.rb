class Api::V0::ConversationsController < ApplicationController
  before_action { authorise_user!(AdminUser::Permissions::API_USER) }
  before_action :find_conversation
  before_action :find_question

  def answer
    answer = @question.answer

    if answer.present?
      render json: AnswerBlueprint.render(answer), status: :ok
    else
      render json: {}, status: :accepted
    end
  end

private

  def find_conversation
    @conversation = Conversation.includes(questions: { answer: %i[sources feedback] })
                                .find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: GenericErrorBlueprint.render(message: "Conversation not found"), status: :not_found
  end

  def find_question
    @question = @conversation.questions.find(params[:question_id])
  rescue ActiveRecord::RecordNotFound
    render json: GenericErrorBlueprint.render(message: "Question not found"), status: :not_found
  end
end
