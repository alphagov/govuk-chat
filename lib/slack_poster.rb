module SlackPoster
  def self.shadow_ban_notification(user_id, test_mode: false)
    return if ENV["AI_SLACK_CHANNEL_WEBHOOK_URL"].nil?

    url = Rails.application.routes.url_helpers.admin_early_access_user_url(
      user_id,
      host: Plek.external_url_for("chat"),
    )

    slack_poster.send_message(
      "#{test_mode ? '[TEST] ' : ''}A new user has been shadow banned. <#{url}|View user>",
    )
  end

  def self.slack_poster
    Slack::Poster.new(
      ENV["AI_SLACK_CHANNEL_WEBHOOK_URL"],
      {
        icon_emoji: ":govukchat:",
        username: "GOV.UK Chat",
        channel: "#private-ai-govuk",
      },
    )
  end
end
