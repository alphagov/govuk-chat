RSpec.describe "rake message_queue tasks" do
  describe "message_queue:create_published_documents_queue" do
    let(:task_name) { "message_queue:create_published_documents_queue" }

    let(:session) do
      instance_double(Bunny::Session, create_channel: channel).tap do |double|
        allow(double).to receive(:start).and_return(double)
      end
    end

    let(:exchange) { instance_double(Bunny::Exchange) }
    let(:channel) { instance_double(Bunny::Channel, queue:) }
    let(:queue) { instance_double(Bunny::Queue, bind: nil) }

    before do
      Rake::Task[task_name].reenable

      allow(Bunny).to receive(:new).and_return(session)
      allow(Bunny::Exchange).to receive(:new).and_return(exchange)
    end

    it "creates a queue on the published_documents exchange that listens to all events" do
      Rake::Task[task_name].invoke
      expect(queue).to have_received(:bind).with(exchange, routing_key: "#")
    end

    it "defaults to a queue named 'govuk_chat_published_documents'" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: nil do
        Rake::Task[task_name].invoke

        expect(channel).to have_received(:queue).with("govuk_chat_published_documents")
      end
    end

    it "configures the queue name based on an environment variable" do
      ClimateControl.modify PUBLISHED_DOCUMENTS_MESSAGE_QUEUE_NAME: "custom_queue_name" do
        Rake::Task[task_name].invoke

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
  end
end
