module MessageQueue
  class MessageProcessor
    delegate :logger, to: Rails

    def process(message)
      payload = message.payload
      base_path = payload["base_path"]

      if base_path.blank?
        logger.info("#{content_identifier(payload)} ignored due to no base_path")
        message.ack
        return
      end

      lock_for_base_path(base_path) do
        result = ContentSynchroniser.call(payload)
        logger.info("#{content_identifier(payload)} synched: #{result}")
      end

      message.ack

    # Occurs when the lock_for_base_path fails due to item already being processed
    rescue ActiveRecord::LockWaitTimeout
      logger.warn("#{content_identifier(payload)} scheduled for retry due to this base_path already being synched")
      message.retry

    # This should only be catching exceptions we can't anticipate and not transient errors
    rescue StandardError => e
      log_standard_error(e, message.payload)
      GovukError.notify(e) # TODO: use sentry context to include information about what failed
      message.discard
    end

  private

    def content_identifier(payload)
      data = [payload["base_path"], payload["content_id"], payload["locale"]]

      "{#{data.compact.join(', ')}}"
    end

    def log_standard_error(error, payload)
      error_text = "#{error.class}: #{error.message}"
      if payload.is_a?(Hash)
        logger.error("#{content_identifier(payload)} processing failed with #{error_text}")
      else
        logger.error("Failed to process message '#{payload.inspect}' with #{error_text}")
      end
    end

    def lock_for_base_path(base_path, &block)
      base_path_version = BasePathVersion.find_or_create_by!(base_path:)
      base_path_version.with_lock("FOR UPDATE NOWAIT", &block)
    end
  end
end
