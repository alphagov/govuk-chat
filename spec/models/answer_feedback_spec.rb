RSpec.describe AnswerFeedback do
  it_behaves_like "exportable by start and end date" do
    let(:conversation) { create(:conversation, end_user_id: "opted-out-id") }
    let(:question) { create(:question, conversation:) }
    let(:answer) { create(:answer, question:) }
    let(:create_record_lambda) { ->(time) { create(:answer_feedback, created_at: time) } }
    let(:create_excluded_record_lambda) { ->(time) { create(:answer_feedback, answer:, created_at: time) } }

    before { allow(Rails.configuration.govuk_chat_private).to receive(:opted_out_end_user_ids).and_return(%w[opted-out-id]) }
  end

  describe ".group_useful_by_label" do
    it "uses the useful boolean to group results by 'useful' and 'not useful'" do
      create_list(:answer_feedback, 4, useful: true)
      create_list(:answer_feedback, 2, useful: false)
      expect(described_class.group_useful_by_label.count).to eq({ "useful" => 4, "not useful" => 2 })
    end
  end

  describe "#serialize for export" do
    it "returns answer_feedback serliazed as json" do
      answer_feedback = create(:answer_feedback)
      expect(answer_feedback.serialize_for_export).to eq(answer_feedback.as_json)
    end
  end
end
