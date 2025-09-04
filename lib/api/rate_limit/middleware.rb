class Api::RateLimit::Middleware
  THROTTLE_TO_PREFIX_MAPPING = {
    Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME => "Govuk-Api-User-Read",
    Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME => "Govuk-Api-User-Write",
    Api::RateLimit::GOVUK_END_USER_READ_THROTTLE_NAME => "Govuk-End-User-Id-Read",
    Api::RateLimit::GOVUK_END_USER_WRITE_THROTTLE_NAME => "Govuk-End-User-Id-Write",
  }.freeze
  SLACK_NOTIFICATION_THRESHOLD_PERCENTAGE = 75

  delegate :logger, to: Rails

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    throttle_data = env["rack.attack.throttle_data"]
    return [status, headers, body] unless throttle_data

    throttle_data.each do |throttle_name, throttle_info|
      header_name_prefix = THROTTLE_TO_PREFIX_MAPPING[throttle_name]

      if header_name_prefix.nil?
        logger.warn("Unknown throttle name: #{throttle_name}")
        next
      end

      limit = throttle_info[:limit]
      count = throttle_info[:count]
      period = throttle_info[:period]
      epoch_time = throttle_info[:epoch_time]
      expires_in = (period - (epoch_time % period)).to_i
      percentage_used = ((count.to_f / limit) * 100).round(2)
      user_name = env.fetch("warden").user.name

      headers["#{header_name_prefix}-RateLimit-Limit"] = limit.to_s
      headers["#{header_name_prefix}-RateLimit-Remaining"] = [limit - count, 0].max.to_s
      headers["#{header_name_prefix}-RateLimit-Reset"] = "#{expires_in}s"

      if header_name_prefix == "Govuk-Api-User-Read"
        PrometheusMetrics.gauge(
          "rate_limit_api_user_read_percentage_used",
          percentage_used,
          { signon_user: user_name },
        )

        if percentage_used >= SLACK_NOTIFICATION_THRESHOLD_PERCENTAGE
          NotifySlackApiUserRateLimitWarningJob.perform_later(
            user_name, percentage_used, "read"
          )
        end
      elsif header_name_prefix == "Govuk-Api-User-Write"
        PrometheusMetrics.gauge(
          "rate_limit_api_user_write_percentage_used",
          percentage_used,
          { signon_user: user_name },
        )

        if percentage_used >= SLACK_NOTIFICATION_THRESHOLD_PERCENTAGE
          NotifySlackApiUserRateLimitWarningJob.perform_later(
            user_name, percentage_used, "write"
          )
        end
      end
    end

    [status, headers, body]
  end
end
