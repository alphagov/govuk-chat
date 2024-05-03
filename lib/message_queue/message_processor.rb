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

      if payload["schema_name"] == "substitute"
        logger.info("#{content_identifier(payload)} ignored as a substitute")
        message.ack
        return
      end

      lock_for_base_path(base_path) do |base_path_version|
        payload_version = payload["payload_version"].to_i

        if base_path_version.payload_version <= payload_version
          result = ContentSynchroniser.call(payload)
          logger.info("#{content_identifier(payload)} synched: #{result}")

          base_path_version.update!(payload_version:)
        else
          logger.info("#{content_identifier(payload)} ignored as it's older than the last version synched")
        end
      end

      message.ack

    # Occurs when the lock_for_base_path fails due to item already being processed
    rescue ActiveRecord::LockWaitTimeout
      logger.warn("#{content_identifier(payload)} scheduled for retry due to this base_path already being synched")
      message.retry

    # Retry when experiencing an error from a supporting service
    rescue OpenSearch::Transport::Transport::Error, OpenAIClient::RequestError => e
      logger.error("#{content_identifier(payload)} scheduled for retry due to error: #{e.class} #{e.message}")
      GovukError.notify(e) # If we experience transient errors we should exclude them from sentry logging
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
      base_path_version.with_lock("FOR UPDATE NOWAIT") { block.call(base_path_version) }
    end
  end
end
