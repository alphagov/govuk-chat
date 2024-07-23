RSpec.describe MessageQueue::MessageProcessor do
  it_behaves_like "a message queue processor"

  describe "#process" do
    context "when given a payload we can index", :chunked_content_index do
      before { stub_any_openai_embedding }

      let(:base_path) { "/news" }
      let(:payload_version) { 20 }

      let(:content_item) do
        build(:notification_content_item,
              schema_name: "detailed_guide",
              base_path:,
              payload_version:,
              body: "<p>Content</p>")
      end

      let(:chunked_content_repository) { Search::ChunkedContentRepository.new }
      let(:message) { create_mock_message(content_item) }

      it "acknowledges the messages" do
        expect { described_class.new.process(message) }
          .to change(message, :acked?)
      end

      it "writes to the search index" do
        expect { described_class.new.process(message) }
          .to change { chunked_content_repository.count(term: { base_path: }) }
          .by(1)
      end

      it "writes to the log" do
        allow(Rails.logger).to receive(:info)
        described_class.new.process(message)

        log_message = "{#{base_path}, #{content_item['content_id']}, #{content_item['locale']}} " \
                      "synched: 1 chunk newly inserted, 0 chunks updated, " \
                      "0 chunks didn't need updating, 0 chunks deleted"

        expect(Rails.logger).to have_received(:info).with(log_message)
      end

      it "creates a base path version model if one does not exist" do
        expect { described_class.new.process(message) }
          .to change(BasePathVersion, :count)
          .by(1)

        expect(BasePathVersion.find_by(base_path:).payload_version)
          .to eq(payload_version)
      end

      it "updates a base path version model if one exists" do
        base_path_version = create(:base_path_version, base_path:)

        expect { described_class.new.process(message) }
          .to change { base_path_version.reload.payload_version }
          .to(payload_version)
      end
    end

    context "when a message payload lacks a base_path" do
      let(:content_item) { build(:notification_content_item, schema_name: "contact", base_path: nil) }

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

    context "when a message payload is a substitute" do
      let(:content_item) { build(:notification_content_item, schema_name: "substitute") }

      let(:message) { create_mock_message(content_item) }

      it "acknowledges the messages" do
        expect { described_class.new.process(message) }
          .to change(message, :acked?)
      end

      it "writes to the log" do
        allow(Rails.logger).to receive(:info)
        described_class.new.process(message)
        expect(Rails.logger).to have_received(:info)
          .with("{#{content_item['base_path']}, #{content_item['content_id']}, #{content_item['locale']}} ignored as a substitute")
      end
    end

    context "when the message contains a payload version older than what we have stored" do
      let(:base_path) { "/path" }

      let(:content_item) do
        build(:notification_content_item,
              schema_name: "news_article",
              base_path:,
              payload_version: 1)
      end

      let(:message) { create_mock_message(content_item) }

      before { create(:base_path_version, base_path:, payload_version: 2) }

      it "acknowledges the messages" do
        expect { described_class.new.process(message) }
          .to change(message, :acked?)
      end

      it "writes to the log" do
        allow(Rails.logger).to receive(:info)
        described_class.new.process(message)

        log_message = "{#{base_path}, #{content_item['content_id']}, #{content_item['locale']}} " \
                      "ignored as it's older than the last version synched"

        expect(Rails.logger).to have_received(:info).with(log_message)
      end
    end

    context "when there is already a base_path being processed" do
      let(:base_path) { "/path" }

      let(:content_item) { build(:notification_content_item, schema_name: "news_article", base_path:) }

      let(:message) { create_mock_message(content_item) }

      let(:base_path_version) { build(:base_path_version, base_path:) }

      before do
        allow(BasePathVersion)
          .to receive(:find_or_create_by!)
          .and_return(base_path_version)

        allow(base_path_version)
          .to receive(:with_lock)
          .with("FOR UPDATE NOWAIT")
          .and_raise(ActiveRecord::LockWaitTimeout)
      end

      it "discards the messages to trigger a retry" do
        expect { described_class.new.process(message) }
          .to change(message, :discarded?)
      end

      it "writes to the log" do
        allow(Rails.logger).to receive(:warn)
        described_class.new.process(message)

        log_message = "{#{base_path}, #{content_item['content_id']}, #{content_item['locale']}} " \
                      "scheduled for retry due to this base_path already being synched"

        expect(Rails.logger).to have_received(:warn).with(log_message)
      end

      context "when the job has been retried the maximum amount of times" do
        let(:message) { create_mock_message(content_item, max_retries_headers) }

        it "acks the message to quit retrying" do
          expect { described_class.new.process(message) }
            .to change(message, :acked?)
        end

        it "writes to the log" do
          allow(Rails.logger).to receive(:error)
          described_class.new.process(message)

          log_message = "{#{base_path}, #{content_item['content_id']}, #{content_item['locale']}} " \
                        "ignored after #{described_class::MAX_RETRIES} retries"

          expect(Rails.logger).to have_received(:error).with(log_message)
        end
      end
    end

    shared_examples "transient error behaviour" do |error_class, error_message|
      it "discards the messages to trigger a retry" do
        expect { described_class.new.process(message) }
          .to change(message, :discarded?)
      end

      it "writes to the log" do
        allow(Rails.logger).to receive(:error)
        described_class.new.process(message)

        log_message = "{#{content_item['base_path']}, #{content_item['content_id']}, #{content_item['locale']}} " \
                      "scheduled for retry due to error: " \
                      "#{error_class} #{error_message}"

        expect(Rails.logger).to have_received(:error).with(log_message)
      end

      context "when the job has been retried the maximum amount of times" do
        let(:message) { create_mock_message(content_item, max_retries_headers) }

        it "acks the message to quit retrying" do
          expect { described_class.new.process(message) }
            .to change(message, :acked?)
        end

        it "writes to the log" do
          allow(Rails.logger).to receive(:error)
          described_class.new.process(message)

          log_message = "{#{content_item['base_path']}, #{content_item['content_id']}, #{content_item['locale']}} " \
                        "ignored after #{described_class::MAX_RETRIES} retries"

          expect(Rails.logger).to have_received(:error).with(log_message)
        end

        it "sets the context and tags correctly for Sentry" do
          sentry_scope = Sentry::Scope.new
          allow(Sentry).to receive(:with_scope).and_yield(sentry_scope)

          described_class.new.process(message)

          expect_sentry_scope_to_be_configured(sentry_scope, message.payload)
        end
      end
    end

    context "when an OpenSearch error is raised" do
      let(:content_item) { build(:notification_content_item, schema_name: "news_article", base_path: "/path") }

      let(:message) { create_mock_message(content_item) }

      before do
        allow(MessageQueue::ContentSynchroniser)
          .to receive(:call)
          .and_raise(OpenSearch::Transport::Transport::Error, "OpenSearch error")
      end

      include_examples "transient error behaviour", OpenSearch::Transport::Transport::Error, "OpenSearch error"
    end

    context "when an OpenAIClient error is raised" do
      let(:content_item) { build(:notification_content_item, schema_name: "news_article", base_path: "/path") }

      let(:message) { create_mock_message(content_item) }

      before do
        allow(MessageQueue::ContentSynchroniser)
          .to receive(:call)
          .and_raise(OpenAIClient::RequestError, "OpenAI error")
      end

      include_examples "transient error behaviour", OpenAIClient::RequestError, "OpenAI error"
    end

    context "when any other exception is raised" do
      let(:message) { create_mock_message(1) }

      it "acks the message" do
        expect { described_class.new.process(message) }
          .to change(message, :acked?)
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
        let(:content_item) { build(:notification_content_item, schema_name: "news_article", base_path: "/path") }
        let(:message) { create_mock_message(content_item) }

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

        it "sets the context and tags correctly for Sentry" do
          allow(MessageQueue::ContentSynchroniser).to receive(:call).and_raise(RuntimeError, "Contrived error")
          sentry_scope = Sentry::Scope.new
          allow(Sentry).to receive(:with_scope).and_yield(sentry_scope)

          described_class.new.process(message)

          expect_sentry_scope_to_be_configured(sentry_scope, message.payload)
        end
      end
    end
  end

  def create_mock_message(...)
    GovukMessageQueueConsumer::MockMessage.new(...)
  end

  def max_retries_headers
    {
      headers: {
        "x-death" => [{ "count" => described_class::MAX_RETRIES },
                      { "count" => described_class::MAX_RETRIES }],
      },
    }
  end

  def expect_sentry_scope_to_be_configured(sentry_scope, payload)
    context_hash = {
      content_id: payload["content_id"],
      locale: payload["locale"],
      base_path: payload["base_path"],
      document_type: payload["document_type"],
      payload_version: payload["payload_version"],
    }

    expect(sentry_scope.contexts["message processer"]).to eq(context_hash)
    expect(sentry_scope.tags).to eq(content_id: payload["content_id"], base_path: payload["base_path"])
  end
end
