class SlackPoster
  def self.test_message(message)
    new.send_message("[TEST] #{message}")
  end

  def self.api_user_rate_limit_warning(signon_name:, percentage_used:, request_type:)
    new.send_message(
      "#{signon_name} is reaching their API user rate limit: #{percentage_used}% of #{request_type} requests used",
    )
  end

  def self.previous_days_api_activity
    message = DailyApiActivityMessage.new(Date.yesterday).message
    new.send_message(message)
  end

  def send_message(message)
    return if webhook_url.nil?

    slack_poster.send_message(message)
  end

private

  def webhook_url
    ENV["AI_SLACK_CHANNEL_WEBHOOK_URL"]
  end

  def slack_poster
    Slack::Poster.new(
      webhook_url,
      {
        icon_emoji: ":govukchat:",
        username: "GOV.UK Chat",
        channel: "#private-ai-govuk",
      },
    )
  end
end
