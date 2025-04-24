class Api::V0::ConversationsController < ApplicationController
  before_action { authorise_user!(SignonUser::Permissions::CONVERSATION_API) }
  before_action :find_conversation, only: %i[show answer]

  def show
    answered_questions = @conversation.questions.joins(:answer)
    pending_question = @conversation.questions.unanswered.last

    render(
      json: ConversationBlueprint.render(@conversation, answered_questions:, pending_question:),
      status: :ok,
    )
  end

  def answer
    question = @conversation.questions.find(params[:question_id])
    answer = question.answer

    if answer.present?
      render json: AnswerBlueprint.render(answer), status: :ok
    else
      render json: {}, status: :accepted
    end
  end

private

  def find_conversation
    @conversation = Conversation
                    .includes(questions: { answer: %i[sources feedback] })
                    .find(params[:conversation_id])
  end
end
