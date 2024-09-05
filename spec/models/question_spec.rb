RSpec.describe Question do
  describe ".unanswered" do
    it "returns all questions without an answer" do
      question = create(:question)
      create(:question, :with_answer)

      expect(described_class.unanswered).to eq [question]
    end
  end

  describe ".active" do
    it "returns questions newer than the configured max_question_age" do
      freeze_time do
        allow(Rails.configuration.conversations).to receive(:max_question_age_days).and_return(1)
        to_find = create(:question, created_at: 1.day.ago)
        create(:question, created_at: 1.day.ago - 1.second)
        expect(described_class.active).to eq([to_find])
      end
    end
  end

  describe ".exportable" do
    context "when new answers have been created since the last export" do
      let(:new_question) { create(:question, created_at: 2.days.ago) }

      before do
        old_question = create(:question, created_at: 4.days.ago - 20.seconds)
        new_question.answer = create(:answer, created_at: 2.days.ago)
        old_question.answer = create(:answer, created_at: 4.days.ago - 20.seconds)
      end

      it "returns questions with answers created since the last export time" do
        last_export = 4.days.ago
        current_time = Time.current

        exportable_questions = described_class.exportable(last_export, current_time)

        expect(exportable_questions.size).to eq(1)
        expect(exportable_questions).to include(new_question)
      end

      it "includes the conversation a question belongs to" do
        last_export = 4.days.ago
        current_time = Time.current

        exportable_questions = described_class.exportable(last_export, current_time)

        expect(exportable_questions.first.association(:conversation).loaded?).to be(true)
      end
    end

    context "when new questions without answers have been created since the last export" do
      it "does not return any questions" do
        create(:question, created_at: 2.days.ago)

        last_export = 4.days.ago
        current_time = Time.current

        exportable_questions = described_class.exportable(last_export, current_time)

        expect(exportable_questions.size).to eq(0)
      end
    end

    context "when no new answers were created since the last export" do
      it "does not return any questions" do
        old_question = create(:question, created_at: 4.days.ago - 20.seconds)
        old_question.answer = create(:answer, created_at: 4.days.ago - 20.seconds)

        last_export = 4.days.ago
        current_time = Time.current

        exportable_questions = described_class.exportable(last_export, current_time)

        expect(exportable_questions.size).to eq(0)
      end
    end
  end

  describe "#answer_status" do
    it "returns the status of the answer" do
      question = create(:question, :with_answer)
      expect(question.answer_status).to eq "success"
    end

    it "returns 'pending' if the question has no answer" do
      question = create(:question)
      expect(question.answer_status).to eq "pending"
    end
  end

  describe "#check_or_create_timeout_answer" do
    it "returns the answer if it exists" do
      question = create(:question, :with_answer)
      expect(question.check_or_create_timeout_answer).to eq(question.answer)
    end

    context "when the answer does not exist and the timeout hasn't expired" do
      it "returns nil" do
        question = create(:question, created_at: 1.minute.ago)
        expect(question.check_or_create_timeout_answer).to be_nil
      end
    end

    context "when the answer does not exist and the timeout has expired" do
      it "creates the answer" do
        question = create(
          :question,
          created_at: Rails.configuration.conversations.answer_timeout_in_seconds.seconds.ago,
        )
        answer = question.check_or_create_timeout_answer

        expect(answer).to have_attributes(
          message: Answer::CannedResponses::TIMED_OUT_RESPONSE,
          status: "abort_timeout",
          question:,
          feedback: nil,
        )
      end
    end
  end

  describe "#serialize_for_export" do
    context "when the question has an answer" do
      it "returns a serialized question with its answer and user id" do
        question = create(:question, :with_answer)
        question.conversation = create(:conversation)
        question.conversation.user = create(:early_access_user)

        expect(question.serialize_for_export)
          .to include(question.as_json)
          .and include("answer" => question.answer.serialize_for_export)
          .and include("early_access_user_id" => question.conversation.early_access_user_id)
      end
    end
  end

  context "when the question does not have an answer" do
    it "returns a serialized question with its answer" do
      question = create(:question)

      expect(question.serialize_for_export)
        .to include(question.as_json)
    end
  end
end
