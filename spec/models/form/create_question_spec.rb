RSpec.describe Form::CreateQuestion do
  let(:hidden_in_unicode_tags) { "\u{E0068}\u{E0069}\u{E0064}\u{E0064}\u{E0065}\u{E006E}" }
  let(:user_question) { "How much tax should I be paying?" }

  describe "validations" do
    let(:conversation) { build(:conversation) }

    it "is valid when user_question is present and 300 chars of less" do
      form = described_class.new(
        conversation:,
        user_question: SecureRandom.alphanumeric(300),
      )
      expect(form).to be_valid
    end

    it "is invalid when user_question has more than 300 chars" do
      form = described_class.new(
        conversation:,
        user_question: SecureRandom.alphanumeric(301),
      )
      form.validate

      expect(form.errors.messages[:user_question])
        .to eq(
          [
            sprintf(
              described_class::USER_QUESTION_LENGTH_ERROR_MESSAGE,
              count: described_class::USER_QUESTION_LENGTH_MAXIMUM,
            ),
          ],
        )
    end

    it "is invalid when user_question is blank" do
      form = described_class.new(
        conversation:,
        user_question: "",
      )
      form.validate

      expect(form.errors.messages[:user_question]).to eq([described_class::USER_QUESTION_PRESENCE_ERROR_MESSAGE])
    end

    it "is invalid when the conversation passed in has an unanswered question" do
      pending_question = build(:question)
      conversation = create(:conversation, questions: [pending_question])
      form = described_class.new(conversation:, user_question:)
      form.validate

      expect(form.errors.messages[:base]).to eq([described_class::UNANSWERED_QUESTION_ERROR_MESSAGE])
    end

    describe "personally identifiable information (pii) validation" do
      it "adds an error message when pii is present" do
        form = described_class.new(
          conversation:,
          user_question: "My email address is email@gmail.com",
        )
        form.validate

        expect(form.errors.messages[:user_question]).to eq([described_class::USER_QUESTION_PII_ERROR_MESSAGE])
      end

      it "doesn't add an error message when no pii is present" do
        form = described_class.new(
          conversation:,
          user_question: "This doesn't have an email address",
        )

        expect(form).to be_valid
      end
    end

    describe "unicode tags" do
      let(:form) do
        described_class.new(
          conversation:,
          user_question: "Message with hidden characters#{hidden_in_unicode_tags}",
        )
      end

      it "is valid with a message containing unicode tags" do
        expect(form).to be_valid
      end

      it "becomes invalid if the message is set to nil" do
        expect { form.user_question = nil }
          .to change(form, :valid?).to(false)
      end
    end

    describe "normalise newlines" do
      it "removes carriage returns before running validations" do
        user_question = "#{'s' * (described_class::USER_QUESTION_LENGTH_MAXIMUM - 1)}\r\n"
        form = described_class.new(
          conversation:,
          user_question:,
        )
        form.validate

        expect(form).to be_valid
      end
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      conversation = build(:conversation)
      form = described_class.new(conversation:)

      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    context "when the conversation passed in on initialisation is persisted" do
      let(:conversation) { create(:conversation, questions: [create(:question, :with_answer, created_at: 31.minutes.ago)]) }

      it "adds a new question with the correct attributes to the conversation" do
        described_class.new(user_question:, conversation:).submit

        expect(Question.where(conversation:).count).to eq 2
        expect(Question.where(conversation:).last)
          .to have_attributes(
            message: user_question,
            unsanitised_message: nil,
            answer_strategy: Rails.configuration.answer_strategy,
            conversation_session_id: an_instance_of(String),
          )
      end

      it "uses the previous questions conversation_session_id if it was created within the last 30 minutes" do
        conversation.questions.last.update!(created_at: 29.minutes.ago)

        described_class.new(user_question:, conversation:).submit

        questions = Question.where(conversation:)
        expect(questions.last.conversation_session_id).to eq(questions.first.conversation_session_id)
      end

      it "enqueues a ComposeAnswerJob" do
        form = described_class.new(conversation:, user_question:)
        expect { form.submit }.to enqueue_job(ComposeAnswerJob)
      end

      context "when the user question contains unicode tags" do
        let(:message_with_unicode_tags) { "Message with hidden characters#{hidden_in_unicode_tags}" }
        let(:form) { described_class.new(conversation:, user_question: message_with_unicode_tags) }

        it "sets a sanitised message on question" do
          form.submit
          expect(Question.where(conversation:).last.message).to eq("Message with hidden characters")
        end

        it "sets the original question as the unsanitised message" do
          form.submit
          expect(Question.where(conversation:).last.unsanitised_message).to eq(message_with_unicode_tags)
        end
      end
    end

    context "when the conversation that is passed is a new record" do
      let(:conversation) { build(:conversation) }

      it "persists the conversation with the users question" do
        form = described_class.new(user_question:, conversation:)

        expect { form.submit }
          .to change(Conversation, :count).by(1)
          .and change(Question, :count).by(1)
      end

      it "returns the created question with the correct attributes" do
        form = described_class.new(user_question:, conversation:)
        question = form.submit

        expect(question)
          .to have_attributes(
            message: user_question,
            answer_strategy: Rails.configuration.answer_strategy,
            conversation_session_id: an_instance_of(String),
          )
      end
    end
  end
end
