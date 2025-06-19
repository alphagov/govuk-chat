class Api::V0::ConversationsController < Api::BaseController
  before_action { authorise_user!(SignonUser::Permissions::CONVERSATION_API) }
  before_action :find_conversation, only: %i[show update answer answer_feedback]

  def create
    conversation = Conversation.new(signon_user: current_user, source: :api)
    form = Form::CreateQuestion.new(question_params.merge(conversation:))

    if form.valid?
      question = form.submit
      render json: QuestionBlueprint.render(question, view: :pending), status: :created
    else
      render json: ValidationErrorBlueprint.render(errors: form.errors.messages), status: :unprocessable_entity
    end
  end

  def show
    answered_questions = @conversation.questions_for_showing_conversation(
      only_answered: true,
      before_timestamp_ms: params[:before_timestamp_ms].presence&.to_i,
    )

    pending_question = @conversation.questions.unanswered.last

    earlier_questions_url = if answered_questions.any? && Question.any_older_questions_in_conversation?(answered_questions.first)
                              api_v0_show_conversation_path(
                                @conversation,
                                before_timestamp_ms: (answered_questions.first.created_at.to_f * 1000).to_i,
                              )
                            end

    json = ConversationBlueprint.render(
      @conversation,
      answered_questions:,
      pending_question:,
      answered_questions_count: @conversation.answered_questions_count,
      earlier_questions_url:,
    )

    render(json:, status: :ok)
  end

  def update
    form = Form::CreateQuestion.new(question_params.merge(conversation: @conversation))

    if form.valid?
      question = form.submit

      render json: QuestionBlueprint.render(question, view: :pending), status: :created
    else
      render json: ValidationErrorBlueprint.render(
        errors: form.errors.messages,
      ), status: :unprocessable_entity
    end
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
                    .active
                    .where(signon_user_id: current_user.id, source: :api)
                    .find(params[:conversation_id])
  end

  def answer_feedback_params
    params.permit(:useful)
  end

  def question_params
    params.permit(:user_question)
  end
end
