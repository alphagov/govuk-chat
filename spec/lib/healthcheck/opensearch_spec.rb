RSpec.describe Healthcheck::Opensearch do
  let(:healthcheck) { described_class.new }

  describe "#name" do
    it "returns ':opensearch'" do
      expect(healthcheck.name).to eq(:opensearch)
    end
  end

  describe "#status" do
    let(:cluster) { instance_double(OpenSearch::API::Cluster::ClusterClient) }
    let(:client) { instance_double(OpenSearch::Client, cluster:) }

    before do
      allow(OpenSearch::Client).to receive(:new).and_return(client)
    end

    context "when the clusters health is green" do
      before do
        allow(cluster).to receive(:health).and_return({ "status" => "green" })
      end

      it "returns GovukHealthcheck::OK" do
        expect(healthcheck.status).to eq(GovukHealthcheck::OK)
      end

      it "does not set the message attribute" do
        healthcheck.status
        expect(healthcheck.message).to be_nil
      end
    end

    context "when the clusters health is yellow" do
      before do
        allow(cluster).to receive(:health).and_return({ "status" => "yellow" })
      end

      it "returns GovukHealthcheck::WARNING" do
        expect(healthcheck.status).to eq(GovukHealthcheck::WARNING)
      end

      it "sets the message attribute to 'Cluster health is yellow'" do
        healthcheck.status
        expect(healthcheck.message).to eq("Cluster health is yellow")
      end
    end

    context "when the clusters health is red" do
      before do
        allow(cluster).to receive(:health).and_return({ "status" => "red" })
      end

      it "returns GovukHealthcheck::CRITICAL" do
        expect(healthcheck.status).to eq(GovukHealthcheck::CRITICAL)
      end

      it "sets the message attribute to 'Cluster health is red'" do
        healthcheck.status
        expect(healthcheck.message).to eq("Cluster health is red")
      end
    end

    context "when an error is raised" do
      before do
        allow(cluster).to receive(:health).and_raise(StandardError, "Contrived error")
      end

      it "returns GovukHealthcheck::CRITICAL" do
        expect(healthcheck.status).to eq(GovukHealthcheck::CRITICAL)
      end

      it "sets the message attribute to the error message" do
        healthcheck.status
        expect(healthcheck.message).to eq("Communicating with OpenSearch failed with a StandardError error")
      end
    end
  end
end
