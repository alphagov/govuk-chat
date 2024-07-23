namespace :message_queue do
  desc "Intended for dev environments - create a queue to listen to all messages on the published_documents exchange"
  task create_published_documents_queue: :environment do
    queue_name = ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME", "govuk_chat_published_documents")
    channel = Bunny.new.start.create_channel

    exchange = channel.fanout("published_documents")
    delay_retry_dlx = channel.fanout("govuk_chat_delay_retry_dlx")
    retry_dlx = channel.fanout("govuk_chat_retry_dlx")

    # discarded messages are routed to delay_retry_dlx
    channel.queue(queue_name, arguments: { "x-dead-letter-exchange" => delay_retry_dlx.name })
           .bind(exchange)

    # messages are queued on delay_retry_dlx for 30s before their ttl completes then are routed to the retry_dlx
    channel.queue("#{queue_name}_delay_retry",
                  arguments: { "x-dead-letter-exchange" => retry_dlx.name, "x-message-ttl" => 30 * 1000 })
           .bind(delay_retry_dlx)

    # messages on the retry_dlx are routed back to the original queue
    channel.queue(queue_name).bind(retry_dlx)
  end

  desc "Run worker to consume published documents from Publishing API message queue"
  task published_documents_consumer: :environment do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME", "govuk_chat_published_documents"),
      processor: MessageQueue::MessageProcessor.new,
      logger: Rails.logger,
      worker_threads: ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_THREADS", "10").to_i,
      prefetch: ENV.fetch("PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_MAX_UNACKED", "10").to_i,
    ).run
  end
end
