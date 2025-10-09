class DailyApiActivityMessage
  def initialize(date)
    @date = date
  end

  def message
    [question_summary, rota_summary].compact.join("\n\n")
  end

private

  attr_reader :date

  def question_summary
    list_items = []

    question_statuses.sort_by { |_, v| -v }.each do |status, count|
      status_config = Rails.configuration.answer_statuses[status]
      status_text = status_config&.label_and_description || status_config&.label
      url_text = "#{count} #{status_text}"
      list_items << "- #{admin_url_slack_link(url_text, status)}"
    end

    potential_question_link = if total_question_count.positive?
                                link_text = "#{total_question_count} #{'question'.pluralize(total_question_count)}"

                                admin_url_slack_link(link_text)
                              else
                                "0 questions"
                              end

    <<~MSG.strip
      Yesterday GOV.UK Chat API received #{potential_question_link}#{total_question_count.zero? ? '.' : ':'}

      #{list_items.join("\n")}
    MSG
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

      Guidance on the daily monitoring of Chat can be found <https://docs.google.com/document/d/1OijsFLKh7azOmOFMWlyZWoqW4PNmE-gffXlPE-qito8/edit?tab=t.0|here>.
    MSG
  end

  def monitoring_rota_config
    Rails.configuration.govuk_chat_private.experiment_monitoring_rota
  end

  def slack_username_for(name)
    "@#{monitoring_rota_config.dig(:slack_usernames, name)}"
  end

  def question_statuses
    @question_statuses ||= Answer.joins(question: :conversation)
                        .where(created_at: date.beginning_of_day..date.end_of_day)
                        .where("conversations.source": "api")
                        .group(:status)
                        .count
  end

  def total_question_count
    @total_question_count ||= question_statuses.values.sum
  end

  def admin_url_slack_link(text, status = nil)
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
      host: Plek.external_url_for(:chat),
    )

    "<#{url}|#{text}>"
  end
end
