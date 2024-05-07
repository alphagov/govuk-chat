class Admin::ConversationsController < Admin::BaseController
  def show
    @conversation = Conversation.includes(questions: :answer)
                                .find(params[:id])

    @questions = @conversation.questions
                              .order(created_at: :desc)
                              .page(params[:page])
  end
end
