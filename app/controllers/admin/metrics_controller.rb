class Admin::MetricsController < Admin::BaseController
  before_action :set_period

  content_security_policy only: :index do |policy|
    # Chartkick makes use of inline styles
    policy.style_src(*policy.style_src, :unsafe_inline)
  end

  def conversations
    scope = Conversation.where(created_at: start_time..)

    render json: count_by_period(scope).chart_json
  end

  def questions
    scope = Question.where(created_at: start_time..).group_by_aggregate_status

    render json: count_by_period(scope).chart_json
  end

  def answer_unanswerable_statuses
    scope = Answer.where(created_at: start_time..)
                  .aggregate_status("unanswerable")
                  .group(:status)

    if @period == :last_7_days
      render json: count_by_period(scope).chart_json
    else
      render json: scope.count.chart_json
    end
  end

  def answer_guardrails_statuses
    scope = Answer.where(created_at: start_time..)
                  .aggregate_status("guardrails")
                  .group(:status)

    if @period == :last_7_days
      render json: count_by_period(scope).chart_json
    else
      render json: scope.count.chart_json
    end
  end

  def answer_error_statuses
    scope = Answer.where(created_at: start_time..)
                  .aggregate_status("error")
                  .group(:status)

    if @period == :last_7_days
      render json: count_by_period(scope).chart_json
    else
      render json: scope.count.chart_json
    end
  end

  def question_routing_labels
    scope = Answer.where(created_at: start_time..)
                  .where.not(question_routing_label: nil)
                  .group(:question_routing_label)

    if @period == :last_7_days
      render json: count_by_period(scope).chart_json
    else
      render json: scope.count.chart_json
    end
  end

  def answer_guardrails_failures
    scope = Answer.where(created_at: start_time..)
                  .answer_guardrails_status_fail
                  .group(:answer_guardrails_failures)

    data = if @period == :last_7_days
             group_by_period(scope, :created_at).count_guardrails_failures(:answer_guardrails_failures)
           else
             scope.count_guardrails_failures(:answer_guardrails_failures)
           end

    render json: data.chart_json
  end

  def question_routing_guardrails_failures
    scope = Answer.where(created_at: start_time..)
                  .question_routing_guardrails_status_fail
                  .group(:question_routing_guardrails_failures)

    data = if @period == :last_7_days
             group_by_period(scope, :created_at).count_guardrails_failures(:question_routing_guardrails_failures)
           else
             scope.count_guardrails_failures(:question_routing_guardrails_failures)
           end

    render json: data.chart_json
  end

  def topics
    scope = AnswerAnalysis.joins(:answer)
                          .where(answer: { created_at: start_time.. })

    primary_topic_scope = scope.where.not(primary_topic: nil)
                               .group(:primary_topic)

    secondary_topic_scope = scope.where.not(secondary_topic: nil)
                                       .group(:secondary_topic)

    if @period == :last_7_days
      primary_topic_counts = group_by_period(primary_topic_scope, "answer.created_at").count
      secondary_topic_counts = group_by_period(secondary_topic_scope, "answer.created_at").count
    else
      primary_topic_counts = primary_topic_scope.count
      secondary_topic_counts = secondary_topic_scope.count
    end

    combined_counts = primary_topic_counts.merge(secondary_topic_counts) do |_name, primary_count, secondary_count|
      primary_count + secondary_count
    end

    render json: combined_counts.chart_json
  end

  def answer_completeness
    scope = Answer.where(created_at: start_time..)
                  .where.not(completeness: nil)
                  .group(:completeness)

    if @period == :last_7_days
      render json: count_by_period(scope).chart_json
    else
      render json: scope.count.chart_json
    end
  end

private

  def set_period
    @period = if params[:period].in?(%w[last_24_hours last_7_days])
                params[:period].to_sym
              else
                :last_24_hours
              end
  end

  def start_time
    @start_time ||= if @period == :last_7_days
                      (Date.current - 6.days).beginning_of_day
                    else
                      (Time.current - 23.hours).beginning_of_hour
                    end
  end

  def group_by_period(scope, field)
    if @period == :last_7_days
      scope.group_by_day(field, last: 7)
    else
      scope.group_by_hour(field, last: 24, format: ->(time) { time.to_fs(:time) })
    end
  end

  def count_by_period(scope, group_field: :created_at)
    count = group_by_period(scope, group_field).count
    remove_empty_count_data(count)
  end

  def remove_empty_count_data(count_data)
    # Groupdate is inconsistent with returning no data or a hash of empty
    # data (single group by hash of zero values, multiple group by empty hash)
    # so we reset any that
    count_data.values.all?(&:zero?) ? {} : count_data
  end
end
