RSpec.describe PrometheusMetrics do
  describe ".register" do
    it "registers the prometheus metrics" do
      described_class::GAUGES.each do |gauge|
        expect(PrometheusExporter::Client.default)
          .to receive(:register)
          .with(:gauge, "#{described_class::PREFIX}#{gauge[:name]}", gauge[:description])
      end

      described_class.register
    end
  end

  describe ".name_with_prefix" do
    it "prefixes the metric name with 'govuk_chat_'" do
      expect(described_class.name_with_prefix("early_access_user_accounts_total"))
        .to eq("govuk_chat_early_access_user_accounts_total")
    end
  end

  describe ".gauge" do
    let(:metric) { instance_double(PrometheusExporter::Client::RemoteMetric) }

    before do
      allow(metric).to receive(:observe)
    end

    it "updates the gauge if a gauge with that name exists" do
      allow(PrometheusExporter::Client.default).to receive(:find_registered_metric).and_return(metric)

      described_class.gauge("openai_remaining_tokens", 90_000_000, { object: "chat.completion", model: "gpt-4o-mini" })

      expect(metric).to have_received(:observe).with(90_000_000, { object: "chat.completion", model: "gpt-4o-mini" })
    end

    context "when in a production environment" do
      it "notifies sentry and returns if the gauge does not exist" do
        allow(GovukError).to receive(:notify)
        allow(Rails.env).to receive(:production?).and_return(true)

        described_class.gauge("non_existant_gauge", 90_000_000, { object: "chat.completion", model: "gpt-4o-mini" })

        expect(GovukError)
          .to have_received(:notify)
          .with("non_existant_gauge is not defined in PrometheusMetrics::GAUGES")
        expect(metric).not_to have_received(:observe)
      end
    end

    context "when in a non production environment" do
      it "raises an error if the gauge does not exist" do
        expect { described_class.gauge("non_existant_gauge", 90_000_000, { object: "chat.completion", model: "gpt-4o-mini" }) }
          .to raise_error("non_existant_gauge is not defined in PrometheusMetrics::GAUGES")
      end
    end
  end
end
