class Admin::MetricsController < Admin::BaseController
  content_security_policy only: :index do |policy|
    # Chartkick makes use of inline styles
    policy.style_src(*policy.style_src, :unsafe_inline)
  end

  def early_access_users
    active = EarlyAccessUser.where(created_at: start_time..)
                            .group(:source)
                            .group_by_day(:created_at)
                            .count

    deleted = DeletedEarlyAccessUser.where(user_created_at: start_time..)
                                    .group(:user_source)
                                    .group_by_day(:user_created_at)
                                    .count

    render json: populate_7_days_data(combine_data(active, deleted)).chart_json
  end

  def waiting_list_users
    active = WaitingListUser.where(created_at: start_time..)
                            .group(:source)
                            .group_by_day(:created_at)
                            .count

    deleted = DeletedWaitingListUser.where(user_created_at: start_time..)
                                    .group(:user_source)
                                    .group_by_day(:user_created_at)
                                    .count

    render json: populate_7_days_data(combine_data(active, deleted)).chart_json
  end

  def conversations
    data = Conversation.where(created_at: start_time..)
                       .group_by_day(:created_at)
                       .count

    render json: populate_7_days_data(data).chart_json
  end

  def questions
    data = Question.where(created_at: start_time..)
                   .group_by_aggregate_status
                   .group_by_day(:created_at)
                   .count

    render json: populate_7_days_data(data).chart_json
  end

  def answer_feedback
    data = AnswerFeedback.where(created_at: start_time..)
                         .group_useful_by_label
                         .group_by_day(:created_at)
                         .count

    render json: populate_7_days_data(data).chart_json
  end

  def answer_abort_statuses
    data = Answer.where(created_at: start_time..)
                 .aggregate_status("abort")
                 .group(:status)
                 .group_by_day(:created_at)
                 .count

    render json: populate_7_days_data(data).chart_json
  end

  def answer_error_statuses
    data = Answer.where(created_at: start_time..)
                 .aggregate_status("error")
                 .group(:status)
                 .group_by_day(:created_at)
                 .count

    render json: populate_7_days_data(data).chart_json
  end

  def question_routing_labels
    data = Answer.where(created_at: start_time..)
                 .where.not(question_routing_label: nil)
                 .group(:question_routing_label)
                 .group_by_day(:created_at)
                 .count

    render json: populate_7_days_data(data).chart_json
  end

  def answer_guardrails_failures
    data = Answer.where(created_at: start_time..)
                 .answer_guardrails_status_fail
                 .group(:answer_guardrails_failures)
                 .group_by_day(:created_at)
                 .count_answer_guardrails_failures

    render json: populate_7_days_data(data).chart_json
  end

private

  def start_time
    @start_time ||= (Date.current - 6.days).beginning_of_day
  end

  def populate_7_days_data(values)
    return values if values.empty?

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
