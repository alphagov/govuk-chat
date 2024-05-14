class QuestionsController < BaseController
  before_action :require_onboarding_completed

  def answer
    @conversation = Conversation.find(params[:conversation_id])
    @question = @conversation.questions.find(params[:id])
    answer = @question.answer

    respond_to do |format|
      if answer.present?
        format.html do
          redirect_to show_conversation_path(@conversation, anchor: helpers.dom_id(answer))
          return
        end
        format.json { render json: answer_success_json(answer), status: :ok }
      else
        format.html { render :pending, status: :accepted }
        format.json { render json: { answer_html: nil }, status: :accepted }
      end
    end
  end

private

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
end
