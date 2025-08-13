class SlackPoster
  def self.test_message(message)
    new.send_message("[TEST] #{message}")
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
