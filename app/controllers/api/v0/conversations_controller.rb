class Api::V0::ConversationsController < ApplicationController
  before_action { authorise_user!(AdminUser::Permissions::API_USER) }
  before_action :find_conversation
  before_action :find_question, only: %i[answer]

  def answer
    answer = @question.answer

    if answer.present?
      render json: AnswerBlueprint.render(answer), status: :ok
    else
      render json: {}, status: :accepted
    end
  end

  def answer_feedback
    answer = @conversation.answers.includes(:feedback).find(params[:answer_id])
    feedback_form = Form::CreateAnswerFeedback.new(answer_feedback_params.merge(answer:))

    if feedback_form.valid?
        feedback_form.submit

        render json: {}, status: :created
      else
        render json: ValidationErrorBlueprint.render(message: "Could not save answer feedback", fields: feedback_form.errors.messages), status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: GenericErrorBlueprint.render(message: "Answer not found"), status: :not_found
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

  def answer_feedback_params
    params.permit(:useful)
  end
end
