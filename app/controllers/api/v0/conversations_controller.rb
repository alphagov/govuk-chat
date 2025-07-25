class Api::V0::ConversationsController < Api::BaseController
  before_action { authorise_user!(SignonUser::Permissions::CONVERSATION_API) }
  before_action :find_conversation, only: %i[show update answer questions]

  def create
    conversation = Conversation.new(
      signon_user: current_user,
      source: :api,
      end_user_id: end_user_id_header,
    )
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
    limit = Rails.configuration.conversations.api_questions_per_page
    answered_questions = @conversation.questions_for_showing_conversation(
      only_answered: true,
      limit:,
    )
    pending_question = @conversation.questions.unanswered.last
    answer_url = pending_question ? answer_path(pending_question) : nil

    earlier_questions_url = if answered_questions.size == limit && @conversation.active_answered_questions_before?(answered_questions.first&.created_at)
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

  def questions
    questions = @conversation.questions_for_showing_conversation(
      only_answered: true,
      before_id: params[:before].presence,
      after_id: params[:after].presence,
      limit: Rails.configuration.conversations.api_questions_per_page,
    )

    earlier_url = if @conversation.active_answered_questions_before?(questions.first&.created_at)
                    api_v0_conversation_questions_path(
                      @conversation,
                      before: questions.first.id,
                    )
                  end

    later_url = if @conversation.active_answered_questions_after?(questions.last&.created_at)
                  api_v0_conversation_questions_path(
                    @conversation,
                    after: questions.last.id,
                  )
                end

    json = ConversationQuestions.new(
      questions: QuestionBlueprint.render_as_hash(questions, view: :answered),
      earlier_questions_url: earlier_url,
      later_questions_url: later_url,
    ).to_json

    render(json:, status: :ok)
  end

private

  def find_conversation
    where = { signon_user_id: current_user.id, source: :api, end_user_id: end_user_id_header }

    @conversation = Conversation
                    .active
                    .where(where)
                    .find(params[:conversation_id])
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

  def end_user_id_header
    request.headers.fetch("HTTP_GOVUK_CHAT_END_USER_ID", "").strip.presence
  end
end
