class ConversationsController < BaseController
  include ActionController::Live

  layout "conversation", except: %i[answer clear]
  before_action :find_conversation
  before_action :require_conversation, only: %i[answer answer_feedback clear]

  def show
    @conversation ||= Conversation.new
    prepare_for_show_view(@conversation)
    @create_question = Form::CreateQuestion.new(conversation: @conversation)
  end

  def clear; end

  def clear_confirm
    cookies.delete(:conversation_id)
    redirect_to show_conversation_path
  end

  def update
    @conversation ||= Conversation.new(signon_user: current_user, source: :web)
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

          render :show, status: :unprocessable_content
        end
        format.json { render json: question_error_json(@create_question), status: :unprocessable_content }
      end
    end
  end

  def answer_stream
    @question = Question.where(conversation: @conversation)
                        .includes(answer: [{ sources: :chunk }, :feedback])
                        .find(params[:question_id])

    random_answer = streamed_answers.sample

    answer = @question.create_answer(message: random_answer, status: :answered)

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Last-Modified"] = Time.zone.now.httpdate
    sse = SSE.new(response.stream, event: "message")

    chunk_string(answer.message).each do |chunk|
      sse.write({ event: "update", message: chunk })
      sleep 0.1
    end
    sse.write({ event: "stream_finished" })
    sse.close
  end

  def answer
    @question = Question.where(conversation: @conversation)
                        .includes(answer: [{ sources: :chunk }, :feedback])
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
        format.json { render json: { error_messages: feedback_form.errors.map(&:message) }, status: :unprocessable_content }
      end
    end
  end

private

  def user_question_params
    params.require(:create_question).permit(:user_question)
  end

  def find_conversation
    return if cookies[:conversation_id].blank?

    @conversation = Conversation.active
                                .where(signon_user: current_user, source: :web)
                                .find_by!(id: cookies[:conversation_id])
    set_conversation_cookie(@conversation)
  rescue ActiveRecord::RecordNotFound
    cookies.delete(:conversation_id)
  end

  def require_conversation
    # Raising an error for Rails responses prevents cookie changes being persisted
    raise ActionController::RoutingError, "Conversation not found" unless @conversation
  end

  def question_success_json(question)
    {
      question_html: render_to_string(
        partial: "question",
        formats: :html,
        locals: { question: },
      ),
      answer_url: answer_stream_question_path(question),
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
      secure: Rails.env.production?,
    }
  end

  def answer_feedback_params
    params.require(:create_answer_feedback).permit(:useful)
  end

  def prepare_for_show_view(conversation)
    @title = "Your conversation"
    @questions = conversation.questions_for_showing_conversation
    @active_conversation = conversation.persisted?
  end

  def streamed_answers
    [
      "<p>When renewing your driving licence, you <strong>do not need</strong> to send your old licence back to DVLA in most cases.</p><p>However, there are some specific situations where you must send your old licence to DVLA:</p><ul><li>if you find your old licence after applying for or receiving a replacement for a lost, stolen, damaged or destroyed licence</li><li>if DVLA writes to you asking for your licence (for example, if you’re a new driver with 6 or more penalty points, have been disqualified, or have changed your address)</li><li>after getting a new lorry or bus licence, if you have not already sent your old licence</li></ul>",
      "<p>You may get a <strong>£150 discount</strong> on your electricity bill if you get Universal Credit and meet the low income criteria for your area.</p><p>Your Winter Fuel Payment amount may be different if you get Universal Credit, but this is primarily for people born before 22 September 1959. Check the Cold Weather Payment eligibility guidance and Warm Home Discount Scheme information on GOV.UK for full details.</p>",
      "<p>If your employer cannot pay its debts, you can apply to the government for:<ul><li>redundancy</li><li>payment holiday pay</li></ul><p>You’re owed outstanding payments like unpaid wages, overtime and commission money you would have earned during your notice period.</p><p>The insolvency practitioner will give you an RP1 fact sheet and a case reference number to use when applying.</p>",
      "<p>You can get Maternity Allowance if you do unpaid work for your spouse or civil partner’s business. To be eligible, for at least <strong>26 weeks</strong> in the 66 weeks before your baby is due, you must have:</p><ul><li>taken part in unpaid work for the business of your spouse or civil partner</li><li>not been employed or self-employed</li></ul><p>In the same 26 weeks, your spouse or civil partner must:</p><ul><li>be registered as self-employed with HMRC</li><li>pay Class 2 National Insurance contributions</li></ul><p>You can get £27 a week for up to 14 weeks if you do unpaid work for your spouse or civil partner’s business.</p>",
    ]
  end

  def chunk_string(string)
    chunks = []
    position = 0

    while position < string.length
      chunk_length = [1, 1, 2, 2, 3, 5, 8].sample
      chunk_length = [chunk_length, string.length - position].min

      chunks << string[position, chunk_length]
      position += chunk_length
    end

    chunks
  end
end
