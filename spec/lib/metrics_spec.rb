RSpec.describe Metrics do
  describe "initialisation" do
    it "registers the prometheus metrics on boot" do
      described_class::COUNTERS.map { |counter| counter[:name] }.each do |counter_name|
        metric = PrometheusExporter::Client.default.find_registered_metric("#{described_class::PREFIX}#{counter_name}")
        expect(metric).to be_a(PrometheusExporter::Client::RemoteMetric)
      end
    end
  end

  describe ".register" do
    it "registers the prometheus metrics" do
      described_class::COUNTERS.each do |counter|
        expect(PrometheusExporter::Client.default)
          .to receive(:register)
          .with(:counter, "#{described_class::PREFIX}#{counter[:name]}", counter[:description], labels: %i[source])
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
end
