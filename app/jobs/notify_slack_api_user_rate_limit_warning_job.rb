class NotifySlackApiUserRateLimitWarningJob < ApplicationJob
  queue_as :default

  def perform(signon_name, percentage_used, request_type)
    SlackPoster.api_user_rate_limit_warning(signon_name:, percentage_used:, request_type:)
  end
end
