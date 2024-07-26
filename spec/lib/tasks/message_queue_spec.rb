RSpec.describe "rake message_queue tasks" do
  describe "message_queue:create_published_documents_queue" do
    let(:task_name) { "message_queue:create_published_documents_queue" }

    let(:session) do
      instance_double(Bunny::Session, create_channel: channel).tap do |double|
        allow(double).to receive(:start).and_return(double)
      end
    end

    let(:exchange) { instance_double(Bunny::Exchange, name: "published_documents") }
    let(:delay_retry_dlx) { instance_double(Bunny::Exchange, name: "govuk_chat_delay_retry_dlx") }
    let(:retry_dlx) { instance_double(Bunny::Exchange, name: "govuk_chat_retry_dlx") }
    let(:channel) { instance_double(Bunny::Channel) }
    let(:queue) { instance_double(Bunny::Queue, bind: nil) }
    let(:delay_retry_queue) { instance_double(Bunny::Queue, bind: nil) }

    before do
      Rake::Task[task_name].reenable

      allow(Bunny).to receive(:new).and_return(session)
      allow(channel).to receive(:fanout).with("published_documents").and_return(exchange)
      allow(channel).to receive(:fanout).with("govuk_chat_delay_retry_dlx")
        .and_return(delay_retry_dlx)
      allow(channel).to receive(:fanout).with("govuk_chat_retry_dlx")
        .and_return(retry_dlx)
    end

    it "creates exchanges and queues with a default queue naming of govuk_chat_published_documents" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: nil do
        allow(channel)
          .to receive(:queue).with("govuk_chat_published_documents", anything)
          .and_return(queue)

        allow(channel)
          .to receive(:queue).with("govuk_chat_published_documents_delay_retry", anything)
          .and_return(delay_retry_queue)

        allow(channel).to receive(:queue).with("govuk_chat_published_documents").and_return(queue)

        Rake::Task[task_name].invoke

        expect(channel).to have_received(:queue).with(
          "govuk_chat_published_documents",
          arguments: { "x-dead-letter-exchange" => "govuk_chat_delay_retry_dlx" },
        )
        expect(channel).to have_received(:queue).with(
          "govuk_chat_published_documents_delay_retry",
          arguments: { "x-dead-letter-exchange" => "govuk_chat_retry_dlx",
                       "x-message-ttl" => 30_000 },
        )
        expect(channel).to have_received(:queue).with("govuk_chat_published_documents")

        expect(queue).to have_received(:bind).with(exchange)
        expect(delay_retry_queue).to have_received(:bind).with(delay_retry_dlx)
        expect(queue).to have_received(:bind).with(retry_dlx)
      end
    end

    it "configures the queue name based on an environment variable" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: "custom_queue_name" do
        allow(channel).to receive(:queue).with("custom_queue_name", anything).and_return(queue)
        allow(channel).to receive(:queue).with("custom_queue_name_delay_retry", anything).and_return(delay_retry_queue)
        allow(channel).to receive(:queue).with("custom_queue_name").and_return(queue)

        Rake::Task[task_name].invoke

        expect(channel).to have_received(:queue).with("custom_queue_name", anything)
        expect(channel).to have_received(:queue).with("custom_queue_name_delay_retry", anything)
        expect(channel).to have_received(:queue).with("custom_queue_name")
      end
    end
  end

  describe "message_queue:published_documents_consumer" do
    let(:task_name) { "message_queue:published_documents_consumer" }

    let(:queue_consumer) { instance_double(GovukMessageQueueConsumer::Consumer, run: nil) }

    before do
      Rake::Task[task_name].reenable

      allow(GovukMessageQueueConsumer::Consumer).to receive(:new).and_return(queue_consumer)
    end

    it "creates a queue consumer and runs it with the MessageQueue::MessageProcessor" do
      Rake::Task[task_name].invoke

      expect(GovukMessageQueueConsumer::Consumer)
        .to have_received(:new)
        .with(hash_including(processor: instance_of(MessageQueue::MessageProcessor)))
      expect(queue_consumer).to have_received(:run)
    end

    it "delegates the Rails logger to the queue consumer" do
      Rake::Task[task_name].invoke

      expect(GovukMessageQueueConsumer::Consumer)
        .to have_received(:new)
        .with(hash_including(logger: Rails.logger))
    end

    it "defaults to a queue named 'govuk_chat_published_documents'" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: nil do
        Rake::Task[task_name].invoke

        expect(GovukMessageQueueConsumer::Consumer)
          .to have_received(:new)
          .with(hash_including(queue_name: "govuk_chat_published_documents"))
      end
    end

    it "configures the queue name based on an environment variable" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: "custom_queue_name" do
        Rake::Task[task_name].invoke

        expect(GovukMessageQueueConsumer::Consumer)
          .to have_received(:new)
          .with(hash_including(queue_name: "custom_queue_name"))
      end
    end

    it "defaults to 10 worker threads" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_THREADS: nil do
        Rake::Task[task_name].invoke

        expect(GovukMessageQueueConsumer::Consumer)
          .to have_received(:new)
          .with(hash_including(worker_threads: 10))
      end
    end

    it "configures the worker threads based on an env var" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_THREADS: "1" do
        Rake::Task[task_name].invoke

        expect(GovukMessageQueueConsumer::Consumer)
          .to have_received(:new)
          .with(hash_including(worker_threads: 1))
      end
    end

    it "defaults to prefetching 10 messages" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_MAX_UNACKED: nil do
        Rake::Task[task_name].invoke

        expect(GovukMessageQueueConsumer::Consumer)
          .to have_received(:new)
          .with(hash_including(prefetch: 10))
      end
    end

    it "configures the prefetching based on an env var" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_MAX_UNACKED: "1" do
        Rake::Task[task_name].invoke

        expect(GovukMessageQueueConsumer::Consumer)
          .to have_received(:new)
          .with(hash_including(prefetch: 1))
      end
    end
  end
end
