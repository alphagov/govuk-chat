class Admin::ConversationsController < Admin::BaseController
  include Admin::Concerns::QuestionFilterConcern

  def show
    conversation = Conversation.includes(questions: :answer)
                                .find(params[:id])
    @filter = questions_filter(conversation)
  end
end
