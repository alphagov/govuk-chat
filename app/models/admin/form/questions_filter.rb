class Admin::Form::QuestionsFilter
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :status, :conversation, :page

  def initialize(status: nil, conversation: nil, page: 1)
    @status = status
    @conversation = conversation
    @page = page.to_i
  end

  def questions
    scope = Question.includes(:answer)
    scope = status_scope(scope)
    scope = conversation_scope(scope)
    scope.order(created_at: :desc)
         .page(page)
         .per(25)
  end

private

  def status_scope(scope)
    return scope if status.blank?

    if status == "pending"
      scope.unanswered
    else
      scope.where(answer: { status: })
    end
  end

  def conversation_scope(scope)
    return scope if conversation.blank?

    scope.where(conversation_id: conversation.id)
  end
end
