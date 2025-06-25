class Api::V0::ConversationsController < Api::BaseController
  before_action { authorise_user!(SignonUser::Permissions::CONVERSATION_API) }
  before_action :find_conversation, only: %i[show update answer answer_feedback questions]

  def create
    conversation = Conversation.new(signon_user: current_user, source: :api)
    form = Form::CreateQuestion.new(question_params.merge(conversation:))

    if form.valid?
      question = form.submit
      render json: QuestionBlueprint.render(
        question,
        view: :pending,
        answer_url: answer_path(question),
      ), status: :created
    else
      render json: ValidationErrorBlueprint.render(errors: form.errors.messages), status: :unprocessable_entity
    end
  end

  def show
    answered_questions = @conversation.questions_for_showing_conversation(
      only_answered: true,
      limit: Rails.configuration.conversations.api_questions_per_page,
    )
    pending_question = @conversation.questions.unanswered.last
    answer_url = pending_question ? answer_path(pending_question) : nil

    earlier_questions_url = if @conversation.active_answered_questions_before?(answered_questions.first&.created_at)
                              api_v0_conversation_questions_path(
                                @conversation, before: answered_questions.first.id
                              )
                            end

    options = {
      answered_questions:,
      pending_question:,
      answer_url:,
      earlier_questions_url:,
    }

    render(
      json: ConversationBlueprint.render(@conversation, options),
      status: :ok,
    )
  end

  def update
    form = Form::CreateQuestion.new(question_params.merge(conversation: @conversation))

    if form.valid?
      question = form.submit

      render json: QuestionBlueprint.render(
        question,
        view: :pending,
        answer_url: answer_path(question),
      ), status: :created
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

  def questions
    questions = @conversation.questions_for_showing_conversation(
      only_answered: true,
      before_id: params[:before].presence,
      after_id: params[:after].presence,
      limit: Rails.configuration.conversations.api_questions_per_page,
    )

    json = ConversationQuestions.new(
      questions: QuestionBlueprint.render_as_hash(questions, view: :answered),
    ).to_json

    render(json:, status: :ok)
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

  def answer_path(question)
    api_v0_answer_question_path(
      question.conversation_id,
      question.id,
    )
  end
end
