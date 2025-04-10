class Api::V0::ConversationsController < ApplicationController
  before_action :authorise_user

  def show
    conversation = Conversation.includes(questions: { answer: %i[sources feedback] })
                                .find(params[:id])
    answered_questions = conversation.questions.joins(:answer)
    pending_question = conversation.questions.unanswered.last

    render json: ConversationBlueprint.render(conversation, answered_questions:, pending_question:), status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: ErrorBlueprint.render_as_hash({ message: e.message }) }, status: :not_found
  end

private

  def authorise_user
    authorise_user!("api-user")
  end
end
