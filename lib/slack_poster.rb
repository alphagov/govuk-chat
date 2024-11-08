class SlackPoster
  def self.shadow_ban_notification(user_id)
    url = Rails.application.routes.url_helpers.admin_early_access_user_url(
      user_id,
      host: Plek.external_url_for("chat"),
    )

    new.send_message("A new user has been shadow banned. <#{url}|View user>")
  end

  def self.waiting_list_full
    new.send_message("The waiting list is full")
  end

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
