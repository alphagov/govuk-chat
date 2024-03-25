class QuestionsController < ApplicationController
  def answer
    @conversation = Conversation.find(params[:conversation_id])
    @question = @conversation.questions.find(params[:id])
    answer = @question.answer

    if answer.present?
      redirect_to show_conversation_path(@conversation, anchor: helpers.dom_id(answer))
      return
    end

    render :pending, status: :accepted
  end
end
