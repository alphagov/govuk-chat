class Api::V0::ConversationsController < ApplicationController
  before_action { authorise_user!(SignonUser::Permissions::CONVERSATION_API) }
  before_action :find_conversation, only: %i[show answer answer_feedback]

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

  def answer_feedback
    answer = @conversation.answers.includes(:feedback).find(params[:answer_id])
    feedback_form = Form::CreateAnswerFeedback.new(answer_feedback_params.merge(answer:))

    if feedback_form.valid?
      feedback_form.submit

      render json: {}, status: :created
    else
      render json: ValidationErrorBlueprint.render(
        errors: feedback_form.errors.messages,
      ), status: :unprocessable_entity
    end
  end

private

  def find_conversation
    @conversation = Conversation
                    .includes(questions: { answer: %i[sources feedback] })
                    .find(params[:conversation_id])
  end

  def answer_feedback_params
    params.permit(:useful)
  end
end
