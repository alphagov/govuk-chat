class DailyApiActivityMessage
  def initialize(date)
    @date = date
  end

  def message
    list_items = []

    statuses.sort_by { |_, v| -v }.each do |status, count|
      status_config = Rails.configuration.answer_statuses[status]
      status_text = status_config&.label_and_description || status_config&.label
      url_text = "#{count} #{status_text}"
      list_items << "* #{admin_url_markdown(url_text, status)}"
    end

    <<~MSG.strip
      Yesterday GOV.UK Chat API received #{total_count} #{total_count == 1 ? 'question' : 'questions'}#{total_count.zero? ? '.' : ':'}

      #{list_items.join("\n")}
    MSG
  end

private

  attr_reader :date

  def statuses
    @statuses ||= Answer.joins(question: :conversation)
                        .where(created_at: date.beginning_of_day..date.end_of_day)
                        .where("conversations.source": "api")
                        .group(:status)
                        .count
  end

  def total_count
    @total_count ||= statuses.values.sum
  end

  def admin_url_markdown(text, status)
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

    "[#{text}](#{url})"
  end
end
