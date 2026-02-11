RSpec.describe AnswerSourceChunk do
  describe ".find_or_create_from_search_result" do
    context "when an answer_source_chunk exists with the unique attributes" do
      it "finds the existing record" do
        existing_chunk = create(:answer_source_chunk)
        unique_attributes = existing_chunk.attributes.slice(*%w[content_id locale chunk_index digest])

        search_result = build(:weighted_search_result, **unique_attributes)
        found_chunk = described_class.find_or_create_from_search_result(search_result)

        expect(found_chunk).to eq(existing_chunk)
      end
    end

    context "when an answer_source_chunk doesn't exist with the unique attributes" do
      it "returns a new answer_source_chunk" do
        other_chunk = create(:answer_source_chunk)
        search_result = build(:weighted_search_result)
        chunk = described_class.find_or_create_from_search_result(search_result)

        expected_attributes = search_result.to_h.except(:_id, :score, :schema_name, :llm_instructions)

        expect(chunk).to be_a(described_class)
        expect(chunk).to have_attributes(expected_attributes)
        expect(chunk).not_to eq(other_chunk)
      end
    end
  end

  describe "#govuk_url" do
    it "concatenates the website root and source path for a URL to GOV.UK" do
      chunk = build(:answer_source_chunk, exact_path: "/income-tax")
      expect(chunk.govuk_url).to eq("#{Plek.website_root}/income-tax")
    end
  end

  describe "#heading" do
    it "returns the last header in the heading hierarchy if there are items" do
      instance = build(:answer_source_chunk, heading_hierarchy: ["Top", "More Specific", "Very Specific"])

      expect(instance.heading).to eq("Very Specific")
    end

    it "returns nil for an empty heading hierarchy" do
      instance = build(:answer_source_chunk, heading_hierarchy: [])

      expect(instance.heading).to be_nil
    end
  end

  describe "#serialize for export" do
    it "returns the model data as json" do
      chunk = build(:answer_source_chunk)
      expect(chunk.serialize_for_export).to eq(chunk.as_json)
    end
  end
end
