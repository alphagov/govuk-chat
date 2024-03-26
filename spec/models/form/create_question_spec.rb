RSpec.describe Form::CreateQuestion do
  include ActiveJob::TestHelper

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

      expect(form.errors.messages[:user_question]).to eq(["Enter a question"])
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
        "Personal data has been detected in your question. Please remove it. You can ask another question. " \
          "But please don’t include personal data in it or in any future questions."
      end

      it "is invalid when the user_question contains an email address" do
        email_addresses = [
          "My email is test@gmail.com",
          "My email is test@g",
        ]

        email_addresses.each do |email_address|
          form = described_class.new(user_question: "My email address is #{email_address}")
          form.validate

          expect(form.errors.messages[:user_question]).to eq([pii_error_message])
        end
      end

      it "is invalid when the user_question contains a credit card number" do
        credit_card_numbers = %w[1234567890123 12345678901234 123456789012345 1234567890123456]

        credit_card_numbers.each do |credit_card_number|
          form = described_class.new(user_question: "My credit card number is #{credit_card_number}")
          form.validate

          expect(form.errors.messages[:user_question]).to eq([pii_error_message])
        end
      end

      it "is invalid when the user_question contains a phone number" do
        phone_numbers = [
          "+44555666777",
          "+(445)555666777",
          "+(445) 555666777",
          "+(445) 555 66677",
          "07555666777",
        ]

        phone_numbers.each do |phone_number|
          form = described_class.new(user_question: "My phone number is #{phone_number}")
          form.validate

          expect(form.errors.messages[:user_question]).to eq([pii_error_message])
        end
      end

      it "is invalid when the user_question contains a national insurance number" do
        ni_numbers = ["AB 12 34 56 A", "AB123456A", "AB 123 456 A", "AB 123 456A", "AB123456 A", "AB 123456A"]

        ni_numbers.each do |ni_number|
          form = described_class.new(user_question: "My ni number is #{ni_number}")
          form.validate

          expect(form.errors.messages[:user_question]).to eq([pii_error_message])
        end
      end
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new

      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    context "when a conversation is passed in on initialisation" do
      it "adds a new question to the conversation" do
        existing_question = build(:question, :with_answer)
        conversation = create(:conversation, questions: [existing_question])

        described_class.new(
          user_question: "How much tax should I be paying?",
          conversation:,
        ).submit

        expect(conversation.reload.questions.count).to eq 2
        expect(conversation.questions.last.message).to eq "How much tax should I be paying?"
      end

      context "with :open_ai feature flag enabled" do
        before do
          stub_feature_flag(:open_ai, true)
        end

        it "fires a GenerateAnswerFromOpenAiJob" do
          form = described_class.new(user_question: "How much tax should I be paying?")
          expect { form.submit }.to change(enqueued_jobs, :size).by(1)
          expect(enqueued_jobs.last)
            .to include(
              job: GenerateAnswerFromOpenAiJob,
              args: [Question.last.id],
            )
        end
      end

      context "without :open_ai feature flag enabled" do
        before do
          stub_feature_flag(:open_ai, false)
        end

        it "fires a GenerateAnswerFromChatApiJob" do
          form = described_class.new(user_question: "How much tax should I be paying?")
          expect { form.submit }.to change(enqueued_jobs, :size).by(1)
          expect(enqueued_jobs.last)
            .to include(
              job: GenerateAnswerFromChatApiJob,
              args: [Question.last.id],
            )
        end
      end
    end

    context "when no conversation is passed in on initialisation" do
      it "creates a new conversation and question" do
        form = described_class.new(user_question: "How much tax should I be paying?")

        expect { form.submit }
          .to change(Conversation, :count).by(1)
          .and change(Question, :count).by(1)
      end

      it "returns the created question with the correct message" do
        form = described_class.new(user_question: "How much tax should I be paying?")
        question = form.submit

        expect(question.message).to eq("How much tax should I be paying?")
      end
    end
  end
end
