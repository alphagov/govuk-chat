RSpec.describe MessageQueue::MessageProcessor do
  it_behaves_like "a message queue processor"

  describe "#process" do
    it "acks messages" do
      mock_message = GovukMessageQueueConsumer::MockMessage.new

      expect { described_class.new.process(mock_message) }
        .to change(mock_message, :acked?)
    end
  end
end
