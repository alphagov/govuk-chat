RSpec.describe AnswerSourceChunk do
  describe ".find_or_create_from_search_result" do
    context "when an answer_source_chunk exists with the unique attributes" do
      it "finds the existing record" do
        existing_chunk = create(:answer_source_chunk)
        unique_attributes = existing_chunk.attributes.slice(*%w[content_id locale chunk_index digest])

        search_result = build(:chunked_content_search_result, **unique_attributes)
        found_chunk = described_class.find_or_create_from_search_result(search_result)

        expect(found_chunk).to eq(existing_chunk)
      end
    end

    context "when an answer_source_chunk doesn't exist with the unique attributes" do
      it "returns a new answer_source_chunk" do
        other_chunk = create(:answer_source_chunk)
        search_result = build(:chunked_content_search_result)
        chunk = described_class.find_or_create_from_search_result(search_result)

        expected_attributes = search_result.to_h.except(:_id, :score)

        expect(chunk).to be_a(described_class)
        expect(chunk).to have_attributes(expected_attributes)
        expect(chunk).not_to eq(other_chunk)
      end
    end
  end
end
