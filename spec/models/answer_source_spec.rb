RSpec.describe AnswerSource do
  describe "#url" do
    it "concatenates the website root and source path" do
      source = build(:answer_source, path: "/income-tax")
      expect(source.url).to eq("#{Plek.website_root}/income-tax")
    end
  end
end
