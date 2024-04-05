RSpec.describe Answer do
  describe "#sources" do
    it "implicitly orders sources by relevancy" do
      answer = create(:answer)
      source_1 = create(:answer_source, answer:, relevancy: 1, url: "/1")
      source_2 = create(:answer_source, answer:, relevancy: 0, url: "/2")

      expect(answer.sources.to_a).to eq([source_2, source_1])
    end
  end

  describe "#status" do
    it "defaults to success" do
      answer = build_stubbed(:answer)

      expect(answer.status).to eq("success")
    end

    %w[success error_non_specific error_answer_service_error abort_forbidden_words].each do |status|
      it "can be set to #{status}" do
        answer = build_stubbed(:answer, status:)

        expect(answer.status).to eq(status)
      end
    end
  end
end
