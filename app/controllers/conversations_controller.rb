class ConversationsController < ApplicationController
  before_action :find_conversation, only: %i[show update]

  def show
    @create_question = Form::CreateQuestion.new(conversation: @conversation)
  end

  def new
    @create_question = Form::CreateQuestion.new
    @conversation = @create_question.conversation

    render :show
  end

  def create
    @create_question = Form::CreateQuestion.new(user_question_params)

    if @create_question.valid?
      question = @create_question.submit

      redirect_to show_conversation_path(question.conversation, anchor: "question-#{question.id}"), flash: { notice: "Your question has been submitted" }
    else
      @conversation = @create_question.conversation

      render :show, status: :unprocessable_entity
    end
  end

  def update
    @create_question = Form::CreateQuestion.new(user_question_params.merge(conversation: @conversation))

    if @create_question.valid?
      question = @create_question.submit

      redirect_to show_conversation_path(@conversation, anchor: "question-#{question.id}"), flash: { notice: "Your question has been submitted" }
    else
      render :show, status: :unprocessable_entity
    end
  end

private

  def user_question_params
    params.require(:create_question).permit(:user_question)
  end

  def find_conversation
    @conversation = Conversation.find(params[:id])
  end
end
