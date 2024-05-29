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

  def previous_page_params
    if questions.prev_page == 1 || questions.prev_page.nil?
      pagination_query_params
    else
      pagination_query_params.merge(page: questions.prev_page)
    end
  end

  def next_page_params
    if questions.next_page.present?
      pagination_query_params.merge(page: questions.next_page)
    else
      pagination_query_params
    end
  end

private

  def pagination_query_params
    filters = {}
    filters[:status] = status if status.present?

    filters
  end

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
