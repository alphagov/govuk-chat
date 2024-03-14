class ConversationsController < ApplicationController
  def new
    @create_question = Form::CreateQuestion.new
  end

  def create
    @create_question = Form::CreateQuestion.new(user_question_params)

    if @create_question.valid?
      @create_question.submit

      redirect_to new_conversation_path, flash: { notice: "Question saved" }
    else
      render :new, status: :unprocessable_entity
    end
  end

  def user_question_params
    params.require(:create_question).permit(:user_question)
  end
end
