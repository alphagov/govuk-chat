RSpec.describe Conversation do
  describe ".active" do
    let(:conversation) { create(:conversation) }

    before do
      allow(Rails.configuration.conversations).to receive(:max_question_age_days).and_return(1)
    end

    context "when the conversation has recent questions" do
      it "returns the conversation" do
        create(:question, conversation:, created_at: 2.days.ago)
        create(:question, conversation:, created_at: 1.day.ago + 1.second)
        create(:question, conversation:, created_at: 1.day.ago + 20.seconds)
        expect(described_class.active).to eq([conversation])
      end
    end

    context "when the conversation has no recent questions" do
      before do
        create(:question, conversation:, created_at: 1.day.ago - 1.second)
      end

      it "returns no conversations" do
        expect(described_class.active.exists?).to be(false)
      end

      it "throws NotFound when attempting to access conversation through the scope" do
        expect { described_class.active.find(conversation.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".questions_for_showing_conversation" do
    let(:conversation) { create(:conversation) }

    before do
      allow(Rails.configuration.conversations).to receive(:max_question_count).and_return(2)
    end

    it "returns the last N active questions based on the configuration value" do
      create(:question, conversation:)
      expected = 2.times.map do |_|
        create(:question, conversation:)
      end
      expect(conversation.reload.questions_for_showing_conversation).to eq(expected)
    end

    context "when only_answered is true" do
      it "returns the last N active answered questions based on the configuration value" do
        create(:question, :with_answer, conversation:)
        expected = 2.times.map do |_|
          create(:question, :with_answer, conversation:)
        end
        create(:question, conversation:)

        expect(conversation.reload.questions_for_showing_conversation(only_answered: true)).to eq(expected)
      end
    end
  end
end
