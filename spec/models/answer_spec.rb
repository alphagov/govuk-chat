RSpec.describe Answer do
  describe "#sources" do
    it "implicitly orders sources by relevancy" do
      answer = create(:answer)
      source_1 = create(:answer_source, answer:, relevancy: 1, path: "/1")
      source_2 = create(:answer_source, answer:, relevancy: 0, path: "/2")

      expect(answer.sources.to_a).to eq([source_2, source_1])
    end
  end

  describe "#status" do
    it "contains the same values as the answer status config except for pending" do
      config_keys_minus_pending = Rails.configuration.answer_statuses.except("pending").keys.sort
      model_keys = described_class.statuses.keys.sort

      expect(model_keys).to eq(config_keys_minus_pending)
    end
  end
end
