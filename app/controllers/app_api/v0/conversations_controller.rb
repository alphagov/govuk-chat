class AppApi::V0::ConversationsController < ApplicationController
  def show
    conversation = Conversation.includes(questions: { answer: %i[sources feedback] })
                                .find(params[:id])
    render json: ConversationBlueprint.render(conversation), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversation not found" }, status: :not_found
  end
end
