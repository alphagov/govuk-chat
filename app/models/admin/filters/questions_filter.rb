class Admin::Filters::QuestionsFilter < Admin::Filters::BaseFilter
  attribute :status
  attribute :search
  attribute :start_date_params, default: {}
  attribute :end_date_params, default: {}
  attribute :conversation
  attribute :answer_feedback_useful, :boolean

  validate :validate_dates

  def self.default_sort
    "-created_at"
  end

  def self.valid_sort_values
    ["created_at", "-created_at", "message", "-message"]
  end

  def initialize(...)
    super
    validate
  end

  def results
    @results ||= begin
      scope = Question.includes(answer: :feedback)
                      .left_outer_joins(:answer)
      scope = search_scope(scope)
      scope = status_scope(scope)
      scope = start_date_scope(scope)
      scope = end_date_scope(scope)
      scope = answer_feedback_useful_scope(scope)
      scope = conversation_scope(scope)
      scope = ordering_scope(scope)
      scope.page(page)
           .per(25)
    end
  end

private

  def pagination_query_params
    filters = {}
    filters[:status] = status if status.present?
    filters[:search] = search if search.present?
    filters[:start_date_params] = start_date_params if start_date_params.values.any?(&:present?)
    filters[:end_date_params] = end_date_params if end_date_params.values.any?(&:present?)
    filters[:sort] = sort if sort != self.class.default_sort
    filters[:answer_feedback_useful] = answer_feedback_useful unless answer_feedback_useful.nil?

    filters
  end

  def search_scope(scope)
    return scope if search.blank?

    scope.where("questions.message ILIKE :search OR answers.rephrased_question ILIKE :search OR answers.message ILIKE :search", search: "%#{search}%")
  end

  def status_scope(scope)
    return scope if status.blank?

    if status == "pending"
      scope.unanswered
    else
      scope.where(answers: { status: })
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

  def answer_feedback_useful_scope(scope)
    return scope if answer_feedback_useful.nil?

    scope.joins(answer: :feedback).where(feedback: { useful: answer_feedback_useful })
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

    @start_date ||= Time.zone.local(
      start_date_params.fetch(:year, ""),
      start_date_params.fetch(:month, ""),
      start_date_params.fetch(:day, ""),
    )
  end

  def end_date
    return if end_date_params.values.all?(&:blank?)

    @end_date ||= Time.zone.local(
      end_date_params.fetch(:year, ""),
      end_date_params.fetch(:month, ""),
      end_date_params.fetch(:day, ""),
    )
  end
end
