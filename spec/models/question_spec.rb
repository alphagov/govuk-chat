RSpec.describe Question do
  describe ".unanswered" do
    it "returns all questions without an answer" do
      question = create(:question)
      create(:question, :with_answer)

      expect(described_class.unanswered).to eq [question]
    end
  end

  describe ".answered" do
    it "returns all questions with an answer" do
      create(:question)
      question = create(:question, :with_answer)

      expect(described_class.answered).to eq [question]
    end
  end

  describe ".group_by_status" do
    it "groups questions by their answer status" do
      create(:question)
      create_list(:answer, 5, status: :answered)
      create_list(:answer, 3, status: :unanswerable_no_govuk_content)
      create_list(:answer, 2, status: :guardrails_answer)
      create(:answer, status: :error_non_specific)
      create(:answer, status: :error_answer_service_error)

      expect(described_class.group_by_status.count).to eq({
        "answered" => 5,
        "unanswerable_no_govuk_content" => 3,
        "guardrails_answer" => 2,
        "error_non_specific" => 1,
        "error_answer_service_error" => 1,
        "pending" => 1,
      })
    end
  end

  describe ".group_by_aggregate_status" do
    it "groups unanswered questions into a 'pending' group" do
      create(:question)

      expect(described_class.group_by_aggregate_status.count).to match(
        hash_including("pending" => 1),
      )
    end

    it "groups questions by the first part of their status" do
      create(:answer, status: :answered)
      create(:answer, status: :unanswerable_no_govuk_content)
      create(:answer, status: :guardrails_answer)
      create(:answer, status: :error_non_specific)
      create(:answer, status: :error_answer_service_error)

      expect(described_class.group_by_aggregate_status.count).to eq({
        "answered" => 1,
        "unanswerable" => 1,
        "guardrails" => 1,
        "error" => 2,
      })
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
    it_behaves_like "exportable by start and end date" do
      let(:create_record_lambda) do
        lambda { |time|
          create(
            :question,
            created_at: time,
            answer: create(:answer, created_at: time),
          )
        }
      end
    end

    it "includes the conversation a question belongs to" do
      question = create(:question, created_at: 2.days.ago)
      create(:answer, question:, created_at: 2.days.ago)
      last_export = 4.days.ago

      current_time = Time.current
      exportable_questions = described_class.exportable(last_export, current_time)

      expect(exportable_questions.first.association(:conversation).loaded?).to be(true)
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
  end

  describe "#answer_status" do
    it "returns the status of the answer" do
      question = create(:question, :with_answer)
      expect(question.answer_status).to eq "answered"
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
          status: "error_timeout",
          question:,
          feedback: nil,
        )
      end
    end
  end

  describe "#serialize_for_export" do
    context "when the question has an answer" do
      it "returns a serialized question" do
        signon_user = build(:signon_user)
        conversation = build(:conversation, signon_user:, end_user_id: "123")
        question = create(:question, :with_answer, conversation:)

        expect(question.serialize_for_export)
          .to include(question.as_json)
          .and include("answer" => question.answer.serialize_for_export)
          .and include("source" => "web")
          .and include("signon_user_id" => signon_user.id)
          .and include("end_user_id" => conversation.hashed_end_user_id)
      end
    end

    context "when the question does not have an answer" do
      it "returns a serialized question without its answer" do
        question = create(:question)

        export = question.serialize_for_export
        expect(export).to include(question.as_json)
        expect(export["answer"]).to be_nil
      end
    end

    context "when the question does not have a signon_user" do
      it "returns a serialized question without its signon user" do
        question = create(:question)

        expect(question.serialize_for_export["signon_user_id"]).to be_nil
      end
    end
  end

  describe "#use_in_rephrasing?" do
    it "delegates to the answer" do
      question = create(:question, :with_answer)
      allow(question.answer).to receive(:use_in_rephrasing?).and_return(true)

      expect(question.use_in_rephrasing?).to be(true)
    end
  end
end
