RSpec.describe AnswerSource do
  describe ".used" do
    it "returns sources where used is 'true'" do
      used_source = create(:answer_source, used: true)
      create(:answer_source, used: false)

      expect(described_class.used).to eq([used_source])
    end
  end

  describe ".unused" do
    it "returns sources where used is 'false'" do
      unused_source = create(:answer_source, used: false)
      create(:answer_source, used: true)

      expect(described_class.unused).to eq([unused_source])
    end
  end

  describe "#serialize for export" do
    it "returns a source serialzed as json with the chunk but without the chunk id" do
      chunk = build(:answer_source_chunk)
      source = build(:answer_source, chunk:)
      json = source.as_json(except: :answer_source_chunk_id).merge(
        "chunk" => chunk.serialize_for_export,
      )
      expect(source.serialize_for_export).to eq(json)
    end
  end
end
