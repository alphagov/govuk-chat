class ConversationsController < BaseController
  layout "conversation"
  before_action :require_onboarding_completed
  before_action :find_conversation

  def show
    @conversation ||= Conversation.new
    @create_question = Form::CreateQuestion.new(conversation: @conversation)
  end

  def update
    @conversation ||= Conversation.new
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
          @conversation = @create_question.conversation

          render :show, status: :unprocessable_entity
        end
        format.json { render json: question_error_json(@create_question), status: :unprocessable_entity }
      end
    end
  end

  def answer
    return redirect_to onboarding_limitations_path unless @conversation

    @question = @conversation.questions.find(params[:question_id])
    answer = @question.answer

    respond_to do |format|
      if answer.present?
        format.html do
          flash[:notice] = "GOV.UK Chat has answered your question"
          redirect_to show_conversation_path(anchor: helpers.dom_id(answer))
        end
        format.json { render json: answer_success_json(answer), status: :ok }
      else
        format.html { render :pending, status: :accepted }
        format.json { render json: { answer_html: nil }, status: :accepted }
      end
    end
  end

private

  def user_question_params
    params.require(:create_question).permit(:user_question)
  end

  def find_conversation
    return if cookies[:conversation_id].blank?

    @conversation = Conversation.find(cookies[:conversation_id])
    set_conversation_cookie(@conversation)
  rescue ActiveRecord::RecordNotFound
    cookies.delete(:conversation_id)
    redirect_to onboarding_limitations_path
  end

  def question_success_json(question)
    {
      question_html: render_to_string(
        partial: "components/conversation_message",
        formats: :html,
        locals: {
          id: helpers.dom_id(question),
          message: question.message,
          is_question: true,
        },
      ),
      answer_url: answer_question_path(question.conversation, question),
      error_messages: [],
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
        partial: "components/conversation_message",
        formats: :html,
        locals: {
          id: helpers.dom_id(answer),
          sources: answer.sources.map(&:url),
          message: answer.message,
        },
      ),
    }
  end

  def set_conversation_cookie(conversation)
    cookies[:conversation_id] = { value: conversation.id, expires: 7.days.from_now }
  end
end
