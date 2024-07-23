module MessageQueue
  class Message
    delegate :payload, :headers, :status, to: :queue_message

    def initialize(queue_message)
      @queue_message = queue_message
    end

    def done
      queue_message.ack
    end

    def retry
      # Our RabbitMQ is configured that discarding a message pushes it to a
      # queue to retry, so we have to a call an unintiuitvely named method to
      # trigger a retry.
      queue_message.discard
    end

    def retries
      # headers doesn't return a hash but a hash like object (Bunny::MessageProperties)
      deaths = (headers[:headers] || {}).fetch("x-death", [])
      # we expect each retry to flag as two deaths (1 for the initial discard,
      # the other for a timeout to delay the retry)
      deaths.sum { |d| d["count"] } / 2
    end

  private

    attr_reader :queue_message
  end
end
