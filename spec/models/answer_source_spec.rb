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
    it "returns a source and it's full production url serialized as json" do
      source = create(:answer_source)
      expected_json = source.as_json.merge("url" => "https://www.gov.uk#{source.exact_path}")
      expect(source.serialize_for_export).to eq(expected_json)
    end
  end
end
