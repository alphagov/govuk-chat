class Admin::MetricsController < Admin::BaseController
  before_action :set_period

  content_security_policy only: :index do |policy|
    # Chartkick makes use of inline styles
    policy.style_src(*policy.style_src, :unsafe_inline)
  end

  def early_access_users
    active_scope = EarlyAccessUser.where(created_at: start_time..).group(:source)
    active_scope = group_by_period(active_scope, :created_at)

    deleted_scope = DeletedEarlyAccessUser.where(user_created_at: start_time..).group(:user_source)
    deleted_scope = group_by_period(deleted_scope, :user_created_at)

    data = combine_data(active_scope.count, deleted_scope.count)

    render json: populate_period_data(data).chart_json
  end

  def waiting_list_users
    active_scope = WaitingListUser.where(created_at: start_time..).group(:source)
    active_scope = group_by_period(active_scope, :created_at)

    deleted_scope = DeletedWaitingListUser.where(user_created_at: start_time..).group(:user_source)
    deleted_scope = group_by_period(deleted_scope, :user_created_at)

    data = combine_data(active_scope.count, deleted_scope.count)

    render json: populate_period_data(data).chart_json
  end

  def conversations
    scope = group_by_period(Conversation.where(created_at: start_time..), :created_at)

    render json: populate_period_data(scope.count).chart_json
  end

  def questions
    scope = Question.where(created_at: start_time..).group_by_aggregate_status
    scope = group_by_period(scope, :created_at)

    render json: populate_period_data(scope.count).chart_json
  end

  def answer_feedback
    scope = AnswerFeedback.where(created_at: start_time..)
                          .group_useful_by_label
    scope = group_by_period(scope, :created_at)

    render json: populate_period_data(scope.count).chart_json
  end

  def answer_abort_statuses
    scope = Answer.where(created_at: start_time..)
                  .aggregate_status("abort")
                  .group(:status)

    if @period == :last_7_days
      data = scope.group_by_day(:created_at).count

      render json: populate_period_data(data).chart_json
    else
      render json: scope.count.chart_json
    end
  end

  def answer_error_statuses
    scope = Answer.where(created_at: start_time..)
                  .aggregate_status("error")
                  .group(:status)

    if @period == :last_7_days
      data = scope.group_by_day(:created_at).count

      render json: populate_period_data(data).chart_json
    else
      render json: scope.count.chart_json
    end
  end

  def question_routing_labels
    scope = Answer.where(created_at: start_time..)
                  .where.not(question_routing_label: nil)
                  .group(:question_routing_label)

    if @period == :last_7_days
      data = scope.group_by_day(:created_at).count

      render json: populate_period_data(data).chart_json
    else
      render json: scope.count.chart_json
    end
  end

  def answer_guardrails_failures
    scope = Answer.where(created_at: start_time..)
                  .answer_guardrails_status_fail
                  .group(:answer_guardrails_failures)

    if @period == :last_7_days
      data = scope.group_by_day(:created_at).count_answer_guardrails_failures

      render json: populate_period_data(data).chart_json
    else
      data = scope.count_answer_guardrails_failures

      render json: data.chart_json
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
      scope.group_by_day(field)
    else
      scope.group_by_hour(field)
    end
  end

  def populate_period_data(values)
    return values if values.empty?

    if @period == :last_7_days
      populate_7_days_data(values)
    else
      populate_24_hours_data(values)
    end
  end

  def populate_24_hours_data(values)
    if values.keys.first.is_a?(Array)
      outer_group = values.keys.group_by(&:first).keys

      outer_group.each_with_object(values) do |group, memo|
        24.times do |index|
          time = start_time + index.hours
          memo[[group, time]] ||= 0
        end
      end
    else
      24.times do |index|
        values[start_time + index.hours] ||= 0
      end
    end

    values.sort.to_h.transform_keys do |key|
      if key.is_a?(Array)
        [*key[0...-1], key.last.to_fs(:time)]
      else
        key.to_fs(:time)
      end
    end
  end

  def populate_7_days_data(values)
    if values.keys.first.is_a?(Array)
      outer_group = values.keys.group_by(&:first).keys

      outer_group.each_with_object(values) do |group, memo|
        7.times do |index|
          date = (start_time + index.days).to_date
          memo[[group, date]] ||= 0
        end
      end
    else
      7.times do |index|
        values[(start_time + index.days).to_date] ||= 0
      end
    end

    values.sort.to_h
  end

  def combine_data(hash_a, hash_b)
    hash_a.merge(hash_b) { |_, a_value, b_value| a_value + b_value }
  end
end
