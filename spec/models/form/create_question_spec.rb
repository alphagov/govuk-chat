RSpec.describe Form::CreateQuestion do
  describe "validations" do
    it "is valid when user_question is present and 300 chars of less" do
      form = described_class.new(user_question: SecureRandom.alphanumeric(300))
      expect(form).to be_valid
    end

    it "is invalid when user_question has more than 300 chars" do
      form = described_class.new(user_question: SecureRandom.alphanumeric(301))
      form.validate

      expect(form.errors.messages[:user_question]).to eq(["Question must be 300 characters or less"])
    end

    it "is invalid when user_question is blank" do
      form = described_class.new(user_question: "")
      form.validate

      expect(form.errors.messages[:user_question]).to eq(["Ask a question. For example, 'how do I register for VAT?'"])
    end

    it "is invalid when the conversation passed in has an unanswered question" do
      pending_question = build(:question)
      conversation = create(:conversation, questions: [pending_question])

      form = described_class.new(user_question: "How much tax should I be paying?", conversation:)
      form.validate

      expect(form.errors.messages[:base]).to eq(["Previous question pending. Please wait for a response"])
    end

    describe "#no_pii_present?" do
      let(:pii_error_message) do
        "Personal data has been detected in your question. Please remove it and try asking again."
      end

      it "adds an error message when pii is present" do
        form = described_class.new(user_question: "My email address is email@gmail.com")
        form.validate

        expect(form.errors.messages[:user_question]).to eq([pii_error_message])
      end

      it "doesn't add an error message when no pii is present" do
        form = described_class.new(user_question: "This doesn't have an email address")

        expect(form).to be_valid
      end
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new

      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    context "when a conversation is passed in on initialisation" do
      it "adds a new question with the correct attributes to the conversation" do
        existing_question = build(:question, :with_answer)
        conversation = create(:conversation, questions: [existing_question])

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
        form = described_class.new(user_question: "How much tax should I be paying?")
        expect { form.submit }.to change(Sidekiq::Queues["default"], :size).by(1)
        expect(Sidekiq::Queues["default"].last["args"])
          .to include(hash_including("job_class" => "ComposeAnswerJob", "arguments" => [Question.last.id]))
      end
    end

    context "when no conversation is passed in on initialisation" do
      it "creates a new conversation and question" do
        form = described_class.new(user_question: "How much tax should I be paying?")

        expect { form.submit }
          .to change(Conversation, :count).by(1)
          .and change(Question, :count).by(1)
      end

      it "returns the created question with the correct attributes" do
        form = described_class.new(user_question: "How much tax should I be paying?")
        question = form.submit

        expect(question)
          .to have_attributes(
            message: "How much tax should I be paying?",
            answer_strategy: "openai_structured_answer",
          )
      end
    end
  end
end
