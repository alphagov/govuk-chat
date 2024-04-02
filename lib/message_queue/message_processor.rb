module MessageQueue
  class MessageProcessor
    def process(message)
      # TODO: add actual logic
      message.ack
    end
  end
end
