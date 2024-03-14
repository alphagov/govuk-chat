class ConversationsController < ApplicationController
  def show
    @create_question = Form::CreateQuestion.new(conversation: Conversation.find(params[:id]))
  end

  def new
    @create_question = Form::CreateQuestion.new
    render :show
  end

  def create
    @create_question = Form::CreateQuestion.new(user_question_params)

    if @create_question.valid?
      question = @create_question.submit

      redirect_to show_conversation_path(question.conversation), flash: { notice: "Your question has been submitted" }
    else
      render :show, status: :unprocessable_entity
    end
  end

  def user_question_params
    params.require(:create_question).permit(:user_question)
  end
end
