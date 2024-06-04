class Admin::ConversationsController < Admin::BaseController
  include Admin::Concerns::QuestionFilterConcern

  def show
    conversation = Conversation.includes(questions: :answer)
                                .find(params[:id])
    @filter = questions_filter(conversation)

    render :show, status: :unprocessable_entity if @filter.errors.present?
  end
end
