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
      expected = 2.times.map do
        create(:question, conversation:)
      end
      expect(conversation.reload.questions_for_showing_conversation).to eq(expected)
    end

    context "when only_answered is true" do
      it "returns the last N active answered questions based on the configuration value" do
        create(:question, :with_answer, conversation:)
        expected = 2.times.map do
          create(:question, :with_answer, conversation:)
        end
        create(:question, conversation:)

        expect(conversation.reload.questions_for_showing_conversation(only_answered: true)).to eq(expected)
      end
    end

    context "when before_id is provided" do
      it "returns questions created before the given question's id" do
        create(:question, conversation:, created_at: 2.hours.ago)
        expected = [
          create(:question, conversation:, created_at: 7.hours.ago),
          create(:question, conversation:, created_at: 6.hours.ago),
        ]
        before_question = create(:question, conversation:, created_at: 3.hours.ago)

        questions = conversation.reload.questions_for_showing_conversation(
          before_id: before_question.id,
        )
        expect(questions).to eq(expected)
      end

      it "raises NotFound if the before_id does not exist" do
        expect {
          conversation.questions_for_showing_conversation(before_id: 9999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when after_id is provided" do
      it "returns questions created after the given question's id" do
        create(:question, conversation:, created_at: 7.hours.ago)
        expected = create(:question, conversation:, created_at: 2.hours.ago)
        after_question = create(:question, conversation:, created_at: 3.hours.ago)

        questions = conversation.reload.questions_for_showing_conversation(
          after_id: after_question.id,
        )
        expect(questions).to eq([expected])
      end

      it "raises NotFound if the after_id does not exist" do
        expect {
          conversation.questions_for_showing_conversation(after_id: 9999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "and there are more questions than the limit" do
        it "returns the first N questions created after the given question's id" do
          create(:question, conversation:, created_at: 1.minute.ago)
          expected = [
            create(:question, conversation:, created_at: 2.hours.ago),
            create(:question, conversation:, created_at: 1.hour.ago),
          ]
          after_question = create(:question, conversation:, created_at: 3.hours.ago)

          questions = conversation.reload.questions_for_showing_conversation(
            after_id: after_question.id,
          )
          expect(questions).to eq(expected)
        end
      end
    end

    context "when a limit is provided" do
      it "returns the last N questions based on the limit" do
        create(:question, :with_answer, conversation:)
        create(:question, :with_answer, conversation:)

        questions = conversation.reload.questions_for_showing_conversation(limit: 1)

        expect(questions.size).to eq(1)
      end
    end

    context "when both before_id and after_id are provided" do
      it "returns all questions created between the two records" do
        after_question = create(:question, conversation:, created_at: 10.hours.ago)
        expected = [
          create(:question, conversation:, created_at: 7.hours.ago),
          create(:question, conversation:, created_at: 6.hours.ago),
        ]
        before_question = create(:question, conversation:, created_at: 2.hours.ago)

        questions = conversation.reload.questions_for_showing_conversation(
          before_id: before_question.id,
          after_id: after_question.id,
        )
        expect(questions).to eq(expected)
      end
    end
  end

  describe "#active_answered_questions_before?" do
    let(:conversation) { create(:conversation) }

    it "returns true if there are older questions" do
      question = create(:question, :with_answer, conversation:, created_at: 2.days.ago)
      create(:question, :with_answer,  conversation:, created_at: 3.days.ago)
      create(:question, :with_answer,  conversation:, created_at: 1.day.ago)

      expect(conversation.active_answered_questions_before?(question.created_at)).to be(true)
    end

    it "returns false if there are no older questions" do
      create(:question, :with_answer, conversation:, created_at: 2.days.ago)
      question = create(:question, :with_answer, conversation:, created_at: 3.days.ago)

      expect(conversation.active_answered_questions_before?(question.created_at)).to be(false)
    end

    it "only includes active questions with answers" do
      create(:question, conversation:, created_at: 2.days.ago)
      create(:question, :with_answer, conversation:, created_at: 5.years.ago)
      question = create(:question, :with_answer, created_at: 1.day.ago)

      expect(conversation.active_answered_questions_before?(question.created_at)).to be(false)
    end
  end

  describe "#active_answered_questions_after?" do
    let(:conversation) { create(:conversation) }

    it "returns true if there are newer questions" do
      question = create(:question, :with_answer, conversation:, created_at: 2.days.ago)
      create(:question, :with_answer, conversation:,  created_at: 3.days.ago)
      create(:question, :with_answer, conversation:,  created_at: 1.day.ago)

      expect(conversation.active_answered_questions_after?(question.created_at)).to be(true)
    end

    it "returns false if there are no newer questions" do
      create(:question, :with_answer, conversation:, created_at: 4.days.ago)
      question = create(:question, :with_answer, conversation:, created_at: 3.days.ago)

      expect(conversation.active_answered_questions_after?(question.created_at)).to be(false)
    end

    it "only includes active questions with answers" do
      question = create(:question, :with_answer, conversation:, created_at: 5.years.ago)
      create(:question, :with_answer, conversation:, created_at: 4.years.ago)
      create(:question, created_at: 1.day.ago)

      expect(conversation.active_answered_questions_after?(question.created_at)).to be(false)
    end
  end

  describe ".hashed_end_user_id" do
    it "returns nil if end_user_id is blank" do
      expect(described_class.hashed_end_user_id(nil)).to be_nil
      expect(described_class.hashed_end_user_id("")).to be_nil
    end

    it "returns the hashed end_user_id" do
      hashed_id = OpenSSL::HMAC.hexdigest(
        "SHA256",
        Rails.application.secret_key_base,
        "12345",
      )

      expect(described_class.hashed_end_user_id("12345")).to eq(hashed_id)
    end
  end

  describe "#hashed_end_user_id" do
    it "returns nil if end_user_id is blank" do
      conversation = create(:conversation, end_user_id: nil)
      expect(conversation.hashed_end_user_id).to be_nil
    end

    it "returns the hashed end_user_id" do
      conversation = create(:conversation, end_user_id: "12345")
      hashed_id = OpenSSL::HMAC.hexdigest(
        "SHA256",
        Rails.application.secret_key_base,
        "12345",
      )

      expect(conversation.hashed_end_user_id).to eq(hashed_id)
    end
  end
end
