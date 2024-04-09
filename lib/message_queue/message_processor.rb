module MessageQueue
  class MessageProcessor
    delegate :logger, to: Rails

    def process(message)
      payload = message.payload

      unless has_base_path?(payload)
        logger.info("#{content_identifier(payload)} ignored due to no base_path")
        message.ack
        return
      end

      # TODO: resolve out of order messages and risks of concurrency
      result = ContentSynchroniser.call(payload)
      logger.info("#{content_identifier(payload)} synched: #{result}")
      message.ack
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

    def has_base_path?(payload)
      payload["base_path"].present?
    end

    def log_standard_error(error, payload)
      error_text = "#{error.class}: #{error.message}"
      if payload.is_a?(Hash)
        logger.error("#{content_identifier(payload)} processing failed with #{error_text}")
      else
        logger.error("Failed to process message '#{payload.inspect}' with #{error_text}")
      end
    end
  end
end
