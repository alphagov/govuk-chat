RSpec.describe Form::CreateQuestion do
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

      expect(form.errors.messages[:user_question]).to eq(["Question must be 300 characters or less"])
    end

    it "is invalid when user_question is blank" do
      form = described_class.new(
        conversation:,
        user_question: "",
      )
      form.validate

      expect(form.errors.messages[:user_question]).to eq(["Ask a question. For example, 'how do I register for VAT?'"])
    end

    it "is invalid when the conversation passed in has an unanswered question" do
      pending_question = build(:question)
      conversation = create(:conversation, questions: [pending_question])
      form = described_class.new(
        conversation:,
        user_question: "How much tax should I be paying?",
      )
      form.validate

      expect(form.errors.messages[:base]).to eq(["Previous question pending. Please wait for a response"])
    end

    describe "#no_pii_present?" do
      let(:pii_error_message) do
        "Personal data has been detected in your question. Please remove it and try asking again."
      end

      it "adds an error message when pii is present" do
        form = described_class.new(
          conversation:,
          user_question: "My email address is email@gmail.com",
        )
        form.validate

        expect(form.errors.messages[:user_question]).to eq([pii_error_message])
      end

      it "doesn't add an error message when no pii is present" do
        form = described_class.new(
          conversation:,
          user_question: "This doesn't have an email address",
        )

        expect(form).to be_valid
      end
    end

    describe "#within_question_limit?" do
      let(:question_limit_error_message) { "You’ve reached the message limit for the GOV.UK Chat trial. You have no messages left." }

      it "adds a error message if over the question limit" do
        conversation.user = build(:early_access_user, questions_count: 2, question_limit: 1)
        form = described_class.new(
          conversation:,
          user_question: "Anything",
        )
        form.validate
        expect(form.errors.messages[:base]).to eq([question_limit_error_message])
      end

      it "is valid when under the question limit" do
        conversation.user = build(:early_access_user, questions_count: 1, question_limit: 2)
        form = described_class.new(
          conversation:,
          user_question: "Anything",
        )
        expect(form).to be_valid
      end

      it "is valid when the conversation has no user" do
        form = described_class.new(
          conversation:,
          user_question: "Anything",
        )
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
      let(:user) { create(:early_access_user) }
      let(:conversation) { create(:conversation, user:, questions: [create(:question, :with_answer)]) }

      it "adds a new question with the correct attributes to the conversation" do
        described_class.new(
          user_question: "How much tax should I be paying?",
          conversation:,
        ).submit

        expect(Question.where(conversation:).count).to eq 2
        expect(Question.where(conversation:).last)
          .to have_attributes(
            message: "How much tax should I be paying?",
            answer_strategy: "openai_structured_answer",
          )
      end

      it "enqueues a ComposeAnswerJob" do
        form = described_class.new(conversation:, user_question: "How much tax should I be paying?")
        expect { form.submit }.to change(Sidekiq::Queues["default"], :size).by(1)
        expect(Sidekiq::Queues["default"].last["args"])
          .to include(hash_including("job_class" => "ComposeAnswerJob", "arguments" => [Question.last.id]))
      end

      it "increments the user's questions_count by 1 if a user is associated with the conversation" do
        form = described_class.new(
          user_question: "How much tax should I be paying?",
          conversation:,
        )
        expect { form.submit }.to change { user.reload.questions_count }.by(1)
      end
    end

    context "when the conversation that is passed is a new record" do
      let(:user) { create(:early_access_user) }
      let(:conversation) { build(:conversation, user:) }

      it "persists the conversation with the users question" do
        form = described_class.new(user_question: "How much tax should I be paying?", conversation:)

        expect { form.submit }
          .to change(Conversation, :count).by(1)
          .and change(Question, :count).by(1)
      end

      it "returns the created question with the correct attributes" do
        form = described_class.new(user_question: "How much tax should I be paying?", conversation:)
        question = form.submit

        expect(question)
          .to have_attributes(
            message: "How much tax should I be paying?",
            answer_strategy: "openai_structured_answer",
          )
      end

      it "associates the conversation with an early access user if present on the conversation" do
        form = described_class.new(user_question: "How much tax should I be paying?", conversation:)
        expect { form.submit }.to change { user.reload.conversations.count }.by(1)
      end

      it "increments the user's questions_count by 1" do
        form = described_class.new(
          user_question: "How much tax should I be paying?",
          conversation:,
        )
        expect { form.submit }.to change { user.reload.questions_count }.by(1)
      end
    end
  end
end
