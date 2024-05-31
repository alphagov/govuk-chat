class Admin::Form::QuestionsFilter
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :status
  attribute :search
  attribute :start_date_params, default: {}
  attribute :end_date_params, default: {}
  attribute :conversation
  attribute :page, :integer

  validate :validate_dates

  def initialize(...)
    super
    validate
  end

  def questions
    @questions ||= begin
      scope = Question.joins("LEFT JOIN answers answer ON answer.question_id = questions.id")
      scope = search_scope(scope)
      scope = status_scope(scope)
      scope = start_date_scope(scope)
      scope = end_date_scope(scope)
      scope = conversation_scope(scope)
      scope.order(created_at: :desc)
          .page(page)
          .per(25)
    end
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
    filters[:search] = search if search.present?
    filters[:start_date_params] = start_date_params if start_date_params.values.any?(&:present?)
    filters[:end_date_params] = end_date_params if end_date_params.values.any?(&:present?)

    filters
  end

  def search_scope(scope)
    return scope if search.blank?

    scope.where("questions.message ILIKE :search OR answer.rephrased_question ILIKE :search OR answer.message ILIKE :search", search: "%#{search}%")
  end

  def status_scope(scope)
    return scope if status.blank?

    if status == "pending"
      scope.unanswered
    else
      scope.where(answer: { status: })
    end
  end

  def start_date_scope(scope)
    return scope if errors[:start_date_params].present? || start_date.nil?

    scope.where("questions.created_at >= ?", start_date)
  end

  def end_date_scope(scope)
    return scope if errors[:end_date_params].present? || end_date.nil?

    scope.where("questions.created_at <= ?", end_date)
  end

  def conversation_scope(scope)
    return scope if conversation.blank?

    scope.where(conversation_id: conversation.id)
  end

  def validate_dates
    begin
      start_date
    rescue ArgumentError
      errors.add(:start_date_params, "Enter a valid start date")
    end

    begin
      end_date
    rescue ArgumentError
      errors.add(:end_date_params, "Enter a valid end date")
    end
  end

  def start_date
    return if start_date_params.values.all?(&:blank?)

    @start_date ||= Time.zone.local(start_date_params[:year], start_date_params[:month], start_date_params[:day])
  end

  def end_date
    return if end_date_params.values.all?(&:blank?)

    @end_date ||= Time.zone.local(end_date_params[:year], end_date_params[:month], end_date_params[:day])
  end
end
