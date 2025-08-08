module Healthcheck
  class Memcache
    attr_reader :message

    def name
      :memcache
    end

    def status
      key = "healthcheck_#{Time.current.to_i}"
      value = "test"

      Rails.cache.write(key, value, expires_in: 10.seconds)
      result = Rails.cache.read(key)
      Rails.cache.delete(key)

      result == value ? GovukHealthcheck::OK : GovukHealthcheck::CRITICAL
    rescue StandardError => e
      @message = e.message
      GovukHealthcheck::CRITICAL
    end

    def enabled?
      ENV["MEMCACHE_SERVERS"].present?
    end
  end
end
