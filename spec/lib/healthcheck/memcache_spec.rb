RSpec.describe Healthcheck::Memcache do
  let(:healthcheck) { described_class.new }

  describe "#name" do
    it "returns ':memcache'" do
      expect(described_class.new.name).to eq(:memcache)
    end
  end

  describe "#status" do
    context "when the memcache server is available" do
      before do
        key = "healthcheck_#{Time.current.to_i}"
        allow(Rails.cache).to receive(:write).with(key, "test", expires_in: 10.seconds).and_return(true)
        allow(Rails.cache).to receive(:read).with(key).and_return("test")
        allow(Rails.cache).to receive(:delete).with(key)
      end

      it "returns GovukHealthcheck::OK" do
        freeze_time do
          expect(healthcheck.status).to eq(GovukHealthcheck::OK)
        end
      end
    end

    context "when the cache item cannot be written" do
      before do
        key = "healthcheck_#{Time.current.to_i}"
        allow(Rails.cache).to receive(:write).with(key, "test", expires_in: 10.seconds).and_return(true)
        allow(Rails.cache).to receive(:read).with(key).and_return(nil)
        allow(Rails.cache).to receive(:delete).with(key)
      end

      it "returns GovukHealthcheck::CRITICAL" do
        freeze_time do
          expect(healthcheck.status).to eq(GovukHealthcheck::CRITICAL)
        end
      end
    end

    context "when an error occurs while checking the cache" do
      before do
        allow(Rails.cache).to receive(:write).and_raise(StandardError, "Cache error")
      end

      it "returns GovukHealthcheck::CRITICAL and sets the message" do
        expect(healthcheck.status).to eq(GovukHealthcheck::CRITICAL)
        expect(healthcheck.message).to eq("Cache error")
      end
    end
  end

  describe "#enabled?" do
    context "when the MEMCACHE_SERVERS env var is set" do
      before do
        allow(ENV).to receive(:[]).with("MEMCACHE_SERVERS").and_return("http://memcache.server")
      end

      it "returns true" do
        expect(healthcheck.enabled?).to be true
      end
    end

    context "when the MEMCACHE_SERVERS env var is not set" do
      it "returns false" do
        expect(healthcheck.enabled?).to be false
      end
    end
  end
end
