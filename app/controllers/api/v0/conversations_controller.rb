class Api::V0::ConversationsController < ApplicationController
  def show
    conversation = Conversation.includes(questions: { answer: %i[sources feedback] })
                                .find(params[:id])
    answered_questions = conversation.questions.joins(:answer)
    pending_question = conversation.questions.unanswered.last

    render json: ConversationBlueprint.render(conversation, answered_questions:, pending_question:), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversation not found" }, status: :not_found
  end
end
