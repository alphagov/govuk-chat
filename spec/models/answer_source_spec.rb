RSpec.describe AnswerSource do
  describe "#url" do
    it "concatenates the website root and source path" do
      source = build(:answer_source, exact_path: "/income-tax")
      expect(source.url).to eq("#{Plek.website_root}/income-tax")
    end
  end

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
    it "returns a source serialzed as json" do
      source = create(:answer_feedback)
      expect(source.serialize_for_export).to eq(source.as_json)
    end
  end
end
