class Api::RateLimit::Middleware
  THROTTLE_TO_PREFIX_MAPPING = {
    Api::RateLimit::GOVUK_API_USER_READ_THROTTLE_NAME => "Govuk-Api-User-Read",
    Api::RateLimit::GOVUK_API_USER_WRITE_THROTTLE_NAME => "Govuk-Api-User-Write",
    Api::RateLimit::GOVUK_CLIENT_DEVICE_READ_THROTTLE_NAME => "Govuk-Client-Device-Id-Read",
    Api::RateLimit::GOVUK_CLIENT_DEVICE_WRITE_THROTTLE_NAME => "Govuk-Client-Device-Id-Write",
  }.freeze

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

      headers["#{header_name_prefix}-RateLimit-Limit"] = limit.to_s
      headers["#{header_name_prefix}-RateLimit-Remaining"] = [limit - count, 0].max.to_s
      headers["#{header_name_prefix}-RateLimit-Reset"] = "#{expires_in}s"
    end

    [status, headers, body]
  end
end
