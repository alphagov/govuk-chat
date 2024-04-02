namespace :message_queue do
  desc "Intended for dev environments - create a queue to listen to all messages on the published_documents exchange"
  task create_published_documents_queue: :environment do
    queue_name = ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME", "govuk_chat_published_documents")
    channel = Bunny.new.start.create_channel
    exchange = Bunny::Exchange.new(channel, :topic, "published_documents")
    channel.queue(queue_name).bind(exchange, routing_key: "#")
  end

  desc "Run worker to consume published documents from Publishing API message queue"
  task published_documents_consumer: :environment do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME", "govuk_chat_published_documents"),
      processor: MessageQueue::MessageProcessor.new,
    ).run
  end
end
