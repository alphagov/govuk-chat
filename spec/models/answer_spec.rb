RSpec.describe Answer do
  describe "#sources" do
    it "implicitly orders sources by relevancy" do
      answer = create(:answer)
      source_1 = create(:answer_source, answer:, relevancy: 1, url: "/1")
      source_2 = create(:answer_source, answer:, relevancy: 0, url: "/2")

      expect(answer.sources.to_a).to eq([source_2, source_1])
    end
  end
end
