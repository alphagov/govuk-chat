class Admin::Filters::QuestionsFilter < Admin::Filters::BaseFilter
  attribute :status
  attribute :search
  attribute :source
  attribute :start_date_params, default: {}
  attribute :end_date_params, default: {}
  attribute :conversation_id
  attribute :answer_feedback_useful, :boolean
  attribute :question_routing_label
  attribute :signon_user_id
  attribute :end_user_id
  attribute :primary_topic
  attribute :secondary_topic
  attribute :completeness
  attribute :conversation_session_id

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
      scope = Question.includes(answer: %i[feedback topics])
                      .left_outer_joins(:answer)
      scope = search_scope(scope)
      scope = status_scope(scope)
      scope = source_scope(scope)
      scope = start_date_scope(scope)
      scope = end_date_scope(scope)
      scope = answer_feedback_useful_scope(scope)
      scope = conversation_scope(scope)
      scope = question_routing_label_scope(scope)
      scope = ordering_scope(scope)
      scope = signon_user_scope(scope)
      scope = end_user_id_scope(scope)
      scope = conversation_session_id_scope(scope)
      scope = primary_topic_scope(scope)
      scope = secondary_topic_scope(scope)
      scope = completeness_scope(scope)
      scope.page(page)
           .per(25)
    end
  end

  def signon_user
    return @signon_user if defined?(@signon_user)

    @signon_user = SignonUser.includes(:conversations).find_by_id(signon_user_id)
  end

  def conversation
    return @conversation if defined?(@conversation)

    @conversation = Conversation.find_by_id(conversation_id)
  end

private

  def pagination_query_params
    filters = {}
    filters[:status] = status if status.present?
    filters[:search] = search if search.present?
    filters[:source] = source if source.present?
    filters[:start_date_params] = start_date_params if start_date_params.values.any?(&:present?)
    filters[:end_date_params] = end_date_params if end_date_params.values.any?(&:present?)
    filters[:sort] = sort if sort != self.class.default_sort
    filters[:answer_feedback_useful] = answer_feedback_useful unless answer_feedback_useful.nil?
    filters[:conversation_id] = conversation.id if conversation.present?
    filters[:signon_user_id] = signon_user_id if signon_user_id.present?
    filters[:end_user_id] = end_user_id if end_user_id.present?
    filters[:question_routing_label] = question_routing_label if question_routing_label.present?
    filters[:primary_topic] = primary_topic if primary_topic.present?
    filters[:secondary_topic] = secondary_topic if secondary_topic.present?
    filters[:completeness] = completeness if completeness.present?
    filters[:conversation_session_id] = conversation_session_id if conversation_session_id.present?

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

  def source_scope(scope)
    return scope if source.blank?

    scope.joins(:conversation).where(conversations: { source: })
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

  def signon_user_scope(scope)
    return scope if signon_user_id.blank?

    scope.joins(:conversation).where("signon_user_id = ?", signon_user_id)
  end

  def end_user_id_scope(scope)
    return scope if end_user_id.blank?

    scope.joins(:conversation).where("end_user_id = ? AND conversations.source = ?", end_user_id, "api")
  end

  def conversation_session_id_scope(scope)
    return scope if conversation_session_id.blank?

    scope.where(conversation_session_id: conversation_session_id)
  end

  def question_routing_label_scope(scope)
    return scope if question_routing_label.blank?

    scope.joins(:answer).where("answers.question_routing_label = ?", question_routing_label)
  end

  def primary_topic_scope(scope)
    return scope if primary_topic.blank?

    scope.joins(answer: :topics)
         .where(answer_analysis_topics: { primary_topic: primary_topic })
  end

  def secondary_topic_scope(scope)
    return scope if secondary_topic.blank?

    scope.joins(answer: :topics)
         .where(answer_analysis_topics: { secondary_topic: secondary_topic })
  end

  def completeness_scope(scope)
    return scope if completeness.blank?

    scope.where(answers: { completeness: })
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
