class DailyApiActivityMessage
  MONITORING_DOC_URL = "https://docs.google.com/document/d/157tV576o_wtT1cpLfrTrmi69iEpDF3RHMIV0gZ4kXyQ/edit?tab=t.1lz7ego30e03#heading=h.eup61djfwacw".freeze

  def initialize(date)
    @date = date
  end

  def message
    [question_summary, rota_summary].compact.join("\n\n")
  end

private

  attr_reader :date

  def question_summary
    summary_prefix = "Yesterday GOV.UK Chat API received"

    return "#{summary_prefix} 0 questions." if total_question_count.zero?

    question_link = admin_url_slack_link(
      "#{total_question_count} #{'question'.pluralize(total_question_count)}",
    )

    end_user_summary = if end_user_count.positive?
                         " from #{end_user_count} end #{'user'.pluralize(end_user_count)}"
                       else
                         ""
                       end

    list_items = question_statuses.sort_by { |k, v| [-v, k] }.map do |status, count|
      status_config = Rails.configuration.answer_statuses[status]
      status_text = status_config&.label_and_description || status_config&.label
      url_text = "#{count} #{status_text}"
      "- #{admin_url_slack_link(url_text, status:)}"
    end

    summary = <<~MSG.strip
      #{summary_prefix} #{question_link}#{end_user_summary}:

      #{list_items.join("\n")}
    MSG

    [summary, suggested_prompt_summary, feedback_summary].compact.join("\n\n")
  end

  def suggested_prompt_summary
    return unless suggested_prompt_count.positive?

    link = admin_url_slack_link(
      "#{suggested_prompt_count} of these questions",
      suggested_prompt: true,
    )
    source = suggested_prompt_count == 1 ? "a suggested prompt" : "suggested prompts"

    "#{link} came from #{source}."
  end

  def feedback_summary
    lines = %i[positive negative].filter_map do |reaction|
      count = feedback_count(reaction)
      next unless count.positive?

      link = admin_url_slack_link("#{count} of these questions", reaction:)
      "#{link} received #{reaction} feedback."
    end

    lines.join("\n").presence
  end

  def rota_summary
    rota = (monitoring_rota_config || {}).fetch(:rota, {})
    name_for_today = rota[Time.zone.today.strftime("%Y-%m-%d")]
    return unless name_for_today

    monitoring_users = [
      "#{name_for_today} (#{slack_username_for(name_for_today)}) - it's your turn to be responsible for monitoring Chat.",
    ]

    name_for_tomorrow = rota[(Time.zone.today + 1).strftime("%Y-%m-%d")]
    if name_for_tomorrow
      monitoring_users << "#{name_for_tomorrow} (#{slack_username_for(name_for_tomorrow)}) - it's your turn tomorrow. Let us know if you're unavailable for your slot so we can find a backup person."
    end

    <<~MSG.strip
      #{monitoring_users.join("\n")}

      Guidance on the daily monitoring of Chat can be found <#{MONITORING_DOC_URL}|here>.
    MSG
  end

  def monitoring_rota_config
    Rails.configuration.govuk_chat_private.experiment_monitoring_rota
  end

  def slack_username_for(name)
    "@#{monitoring_rota_config.dig(:slack_usernames, name)}"
  end

  def question_statuses
    @question_statuses ||= Question.group_by_status
                                   .joins(:conversation)
                                   .where(created_at: date_range)
                                   .where(conversations: { source: :api })
                                   .count
  end

  def total_question_count
    @total_question_count ||= question_statuses.values.sum
  end

  def end_user_count
    return 0 unless total_question_count.positive?

    @end_user_count ||= Question.joins(:conversation)
                                .where(created_at: date_range)
                                .where(conversation: { source: :api })
                                .where.not(conversation: { end_user_id: nil })
                                .distinct
                                .count(:end_user_id)
  end

  def suggested_prompt_count
    @suggested_prompt_count ||= Question.joins(:conversation)
                                        .where(created_at: date_range, suggested_prompt: true)
                                        .where(conversations: { source: :api })
                                        .count
  end

  def feedback_count(reaction)
    Question.joins(:conversation, answer: :feedback)
            .where(created_at: date_range)
            .where(conversations: { source: :api })
            .where(answer_feedback: { reaction: })
            .count
  end

  def date_range
    date.beginning_of_day..date.end_of_day
  end

  def admin_url_slack_link(text, status: nil, suggested_prompt: nil, reaction: nil)
    start_date_params = {
      day: date.day,
      month: date.month,
      year: date.year,
    }
    end_date_params = {
      day: (date + 1).day,
      month: (date + 1).month,
      year: (date + 1).year,
    }

    url = Rails.application.routes.url_helpers.admin_questions_url(
      source: :api,
      start_date_params:,
      end_date_params:,
      status:,
      suggested_prompt:,
      reaction:,
      host: Plek.external_url_for(:chat),
    )

    "<#{url}|#{text}>"
  end
end
