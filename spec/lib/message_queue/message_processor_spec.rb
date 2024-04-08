RSpec.describe MessageQueue::MessageProcessor do
  it_behaves_like "a message queue processor"

  describe "#process" do
    context "when given a payload we can index", :chunked_content_index do
      before { stub_any_openai_embedding }

      let(:content_item) do
        schema = GovukSchemas::Schema.find(notification_schema: "news_article")
        GovukSchemas::RandomExample.new(schema:).payload.tap do |item|
          item["locale"] = "en"
          item["base_path"] = "/news"
          item["details"]["body"] = "<p>Content</p>"
          item.delete("withdrawn_notice")
        end
      end

      let(:chunked_content_repository) { Search::ChunkedContentRepository.new }
      let(:message) { create_mock_message(content_item) }

      it "acknowledges the messages" do
        expect { described_class.new.process(message) }
          .to change(message, :acked?)
      end

      it "writes to the search index" do
        expect { described_class.new.process(message) }
          .to change { chunked_content_repository.count(term: { base_path: "/news" }) }
          .by(1)
      end

      it "writes to the log" do
        allow(Rails.logger).to receive(:info)
        described_class.new.process(message)
        expect(Rails.logger).to have_received(:info)
          .with("{#{content_item['content_id']}, #{content_item['locale']}} synched: 1 chunk newly inserted, 0 chunks updated, 0 chunks deleted")
      end
    end

    context "when a message payload lacks a base_path" do
      let(:content_item) do
        schema = GovukSchemas::Schema.find(notification_schema: "contact")
        GovukSchemas::RandomExample.new(schema:).payload.tap do |item|
          item["base_path"] = nil
        end
      end

      let(:message) { create_mock_message(content_item) }

      it "acknowledges the messages" do
        expect { described_class.new.process(message) }
          .to change(message, :acked?)
      end

      it "writes to the log" do
        allow(Rails.logger).to receive(:info)
        described_class.new.process(message)
        expect(Rails.logger).to have_received(:info)
          .with("{#{content_item['content_id']}, #{content_item['locale']}} ignored due to no base_path")
      end
    end

    context "when an exception is raised" do
      let(:message) { create_mock_message(1) }

      it "discards the message" do
        expect { described_class.new.process(message) }
          .to change(message, :discarded?)
      end

      it "sends the error to GovukError" do
        allow(GovukError).to receive(:notify)
        described_class.new.process(message)
        expect(GovukError).to have_received(:notify).with(kind_of(StandardError))
      end

      context "when the payload is not a hash" do
        it "logs the error without any identifying information" do
          allow(Rails.logger).to receive(:error)
          described_class.new.process(message)
          expect(Rails.logger).to have_received(:error)
            .with("Failed to process message '1' with TypeError: no implicit conversion of String into Integer")
        end
      end

      context "when the payload is a hash" do
        it "logs the error with identifying information" do
          call_count = 0
          content_id = SecureRandom.uuid

          # setup to raise error on first call and return a hash on subsequent calls
          allow(message).to receive(:payload) do
            call_count += 1
            raise "Contrived error" if call_count == 1

            { "content_id" => content_id, "locale" => "en" }
          end

          allow(Rails.logger).to receive(:error)
          described_class.new.process(message)
          expect(Rails.logger).to have_received(:error)
            .with("{#{content_id}, en} processing failed with RuntimeError: Contrived error")
        end
      end
    end
  end

  def create_mock_message(...)
    GovukMessageQueueConsumer::MockMessage.new(...)
  end
end
