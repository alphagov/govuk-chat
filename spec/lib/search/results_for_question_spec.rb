RSpec.describe Search::ResultsForQuestion, :chunked_content_index do
  describe "#self.call" do
    let(:openai_embedding) { mock_openai_embedding(question_message) }
    let(:question_message) { "How much tax should i pay?" }

    before do
      allow(Search::TextToEmbedding)
      .to receive(:call)
      .with(question_message)
      .and_return(openai_embedding)

      populate_chunked_content_index([
        build(:chunked_content_record, openai_embedding:),
        build(:chunked_content_record),
        build(:chunked_content_record),
      ])
    end

    it "retrieves an embedding for the question_message and searches the chunked content repository" do
      result = described_class.call(question_message)
      expect(result).to all be_a(Search::ChunkedContentRepository::Result)
    end
  end
end
