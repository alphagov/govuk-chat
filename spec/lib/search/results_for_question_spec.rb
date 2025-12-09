RSpec.describe Search::ResultsForQuestion, :chunked_content_index do
  describe "#self.call" do
    let(:titan_embedding) { mock_titan_embedding(question_message) }
    let(:question_message) { "How much tax should i pay?" }
    let(:min_score) { 0.5 }
    let(:max_results) { 20 }

    before do
      allow(Search::TextToEmbedding)
        .to receive(:call)
        .with(question_message)
        .and_return(titan_embedding)

      allow(Rails.configuration.search.thresholds).to receive_messages(minimum_score: min_score, max_results:)

      allow(described_class::Reranker).to receive(:document_type_weighting).with("guide", "guide", parent_document_type: nil).and_return(1.0)
      allow(described_class::Reranker).to receive(:document_type_weighting).with("corporate_information_page", "about", parent_document_type: nil).and_return(0.3)
      allow(described_class::Reranker).to receive(:document_type_weighting).with("help_page", "help_page", parent_document_type: nil).and_return(0.4)

      populate_chunked_content_index([
        build(:chunked_content_record, title: "find this", schema_name: "guide", document_type: "guide", titan_embedding:),
        build(:chunked_content_record, title: "not found 1", schema_name: "help_page", document_type: "help_page", titan_embedding:),
        build(:chunked_content_record, title: "not found 2", schema_name: "corporate_information_page", document_type: "about", titan_embedding:),
      ])

      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5, 101.6, 103.6, 103.7, 104.7)
    end

    it "retrieves an embedding for the question_message and searches the chunked content repository" do
      result = described_class.call(question_message)
      expect(result).to be_a(Search::ResultsForQuestion::ResultSet)
      expect(Search::TextToEmbedding).to have_received(:call).with(question_message)
    end

    it "has the results over the configured threshold after reranking" do
      result = described_class.call(question_message)
      expect(result.results).to all be_a(Search::ResultsForQuestion::WeightedResult)
      expect(result.results.map { |r| [r.title, r.weighted_score] })
        .to contain_exactly(["find this", a_value_between(0.9, 1)])
    end

    it "has the rejected results after reranking" do
      result = described_class.call(question_message)
      expect(result.rejected_results).to all be_a(Search::ResultsForQuestion::WeightedResult)
      expect(result.rejected_results.map { |r| [r.title, r.weighted_score] })
        .to contain_exactly(["not found 1", a_value_between(0.3, 0.4)],
                            ["not found 2", a_value_between(0.2, 0.3)])
    end

    it "populates the metrics attribute" do
      result = described_class.call(question_message)
      expect(result.metrics).to eq({ embedding_duration: 1.5, search_duration: 2.0, reranking_duration: 1.0, embedding_provider: "titan" })
    end

    context "when then are more results than the configured max_results" do
      let(:min_score) { 0.1 }
      let(:max_results) { 2 }

      it "respects the max_results configuration value" do
        result = described_class.call(question_message)
        expect(result.results.map { |r| [r.title, r.weighted_score] })
          .to contain_exactly(["find this", a_value_between(0.9, 1)],
                              ["not found 1", a_value_between(0.3, 0.4)])
        expect(result.rejected_results.map { |r| [r.title, r.weighted_score] })
          .to contain_exactly(["not found 2", a_value_between(0.2, 0.3)])
      end
    end
  end
end
