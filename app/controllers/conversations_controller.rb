class ConversationsController < BaseController
  layout "conversation", except: %i[answer clear]
  before_action :require_onboarding_completed
  before_action :find_conversation
  before_action :require_conversation, only: %i[answer answer_feedback clear]

  def show
    @conversation ||= Conversation.new
    prepare_for_show_view(@conversation)
    @create_question = Form::CreateQuestion.new(conversation: @conversation)
    @remaining_questions_copy = helpers.remaining_questions_copy(@conversation.user)

    respond_to do |format|
      format.html { render :show }
      format.json do
        if cookies[:conversation_id].blank?
          render json: {
            title: @title,
            conversation_data: @conversation_data_attributes,
            conversation_append_html: render_to_string(partial: "get_started_messages",
                                                       formats: :html),
            form_html: render_to_string(partial: "form",
                                        formats: :html,
                                        locals: { create_question: @create_question }),
          }
        else
          render json: {}, status: :bad_request
        end
      end
    end
  end

  def clear; end

  def clear_confirm
    cookies.delete(:conversation_id)
    redirect_to show_conversation_path
  end

  def update
    @conversation ||= Conversation.new(user: current_early_access_user)
    @create_question = Form::CreateQuestion.new(user_question_params.merge(conversation: @conversation))

    if @create_question.valid?
      question = @create_question.submit
      set_conversation_cookie(question.conversation) if cookies[:conversation_id].blank?

      respond_to do |format|
        format.html { redirect_to answer_question_path(question) }
        format.json { render json: question_success_json(question), status: :created }
      end
    else
      respond_to do |format|
        format.html do
          prepare_for_show_view(@create_question.conversation)

          render :show, status: :unprocessable_entity
        end
        format.json { render json: question_error_json(@create_question), status: :unprocessable_entity }
      end
    end
  end

  def answer
    @question = Question.where(conversation: @conversation)
                        .includes(answer: %i[sources feedback])
                        .find(params[:question_id])
    answer = @question.check_or_create_timeout_answer

    respond_to do |format|
      if answer.present?
        format.html do
          flash[:notice] = {
            message: "GOV.UK Chat has answered your question",
            link_text: "View your answer",
            link_href: "##{helpers.dom_id(answer)}",
          }
          redirect_to show_conversation_path
        end
        format.json { render json: answer_success_json(answer), status: :ok }
      else
        format.html { render :pending, status: :accepted }
        format.json { render json: { answer_html: nil }, status: :accepted }
      end
    end
  end

  def answer_feedback
    answer = @conversation.answers.includes(:feedback).find(params[:answer_id])
    feedback_form = Form::CreateAnswerFeedback.new(answer_feedback_params.merge(answer:))

    respond_to do |format|
      if feedback_form.valid?
        feedback_form.submit

        format.html { redirect_to show_conversation_path, notice: "Feedback submitted successfully." }
        format.json { render json: { error_messages: [] }, status: :created }
      else
        format.html { redirect_to show_conversation_path }
        format.json { render json: { error_messages: feedback_form.errors.map(&:message) }, status: :unprocessable_entity }
      end
    end
  end

private

  def user_question_params
    params.require(:create_question).permit(:user_question)
  end

  def find_conversation
    return if cookies[:conversation_id].blank?

    @conversation = Conversation.includes(:user).active.find_by!(id: cookies[:conversation_id], user: current_early_access_user)
    set_conversation_cookie(@conversation)
  rescue ActiveRecord::RecordNotFound
    cookies.delete(:conversation_id)
    conversation_not_found
  end

  def require_conversation
    conversation_not_found unless @conversation
  end

  def conversation_not_found
    respond_to do |format|
      format.html { redirect_to onboarding_limitations_path }
      format.json { render json: { error: "Conversation not found" }, status: :not_found }
    end
  end

  def question_success_json(question)
    {
      question_html: render_to_string(
        partial: "question",
        formats: :html,
        locals: { question: },
      ),
      answer_url: answer_question_path(question),
      error_messages: [],
      remaining_questions_copy: helpers.remaining_questions_copy(question.conversation.user),
    }
  end

  def question_error_json(create_question)
    {
      question_html: nil,
      answer_url: nil,
      error_messages: create_question.errors.map(&:message),
    }
  end

  def answer_success_json(answer)
    {
      answer_html: render_to_string(
        partial: "answer",
        formats: :html,
        locals: { answer:, question_limit_warning: true },
      ),
    }
  end

  def set_conversation_cookie(conversation)
    cookies[:conversation_id] = {
      value: conversation.id,
      expires: Rails.configuration.conversations.max_question_age_days.days.from_now,
    }
  end

  def answer_feedback_params
    params.require(:create_answer_feedback).permit(:useful)
  end

  def prepare_for_show_view(conversation)
    @title = "Your conversation"
    @questions = conversation.questions_for_showing_conversation
    @more_information = session[:more_information].present?
    @conversation_data_attributes = { module: "chat-conversation" }
    @active_conversation = conversation.persisted?
  end

  def require_onboarding_completed
    return if session[:onboarding] == "conversation" ||
      cookies[:conversation_id].present? ||
      current_early_access_user&.onboarding_completed

    respond_to do |format|
      format.html { redirect_to onboarding_limitations_path }
      format.json { render json: { error: "Onboarding incomplete" }, status: :bad_request }
    end
  end
end
