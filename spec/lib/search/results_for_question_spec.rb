RSpec.describe Search::ResultsForQuestion, :chunked_content_index do
  describe "#self.call" do
    let(:openai_embedding) { mock_openai_embedding(question_message) }
    let(:question_message) { "How much tax should i pay?" }
    let(:min_score) { 0.5 }
    let(:max_results) { 20 }

    before do
      allow(Search::TextToEmbedding)
        .to receive(:call)
        .with(question_message)
        .and_return(openai_embedding)

      allow(Rails.configuration.search.thresholds).to receive_messages(minimum_score: min_score, max_results:)
      stub_const("Search::ResultsForQuestion::Reranker::DOCUMENT_TYPE_WEIGHTINGS",
                 { "guide" => 1.0, "notice" => 0.4, "about" => 0.3 })

      populate_chunked_content_index([
        build(:chunked_content_record, title: "find this", document_type: "guide", openai_embedding:),
        build(:chunked_content_record, title: "not found 1", document_type: "notice", openai_embedding:),
        build(:chunked_content_record, title: "not found 2", document_type: "about", openai_embedding:),
      ])
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
