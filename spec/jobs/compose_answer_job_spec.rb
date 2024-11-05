RSpec.describe ComposeAnswerJob do
  let(:question) { create(:question, message: user_input) }
  let(:user_input) { "hello" }
  let(:returned_answer) { build :answer, :with_sources, question:, message: "Hello, how can I help you?" }

  before do
    allow(AnswerComposition::Composer).to receive(:call).and_return(returned_answer)
  end

  describe "#perform" do
    it "saves the answer and sources" do
      expect { described_class.new.perform(question.id) }
        .to change(Answer, :count).by(1)
        .and change(AnswerSource, :count).by(2)
    end

    context "when the answer is an abort_jailbreak_guardrails and a user is assoicated with the question" do
      it "calls #handle_jailbreak_attempt on the user" do
        user = create(:early_access_user)
        conversation = create(:conversation, user:)
        question = create(:question, conversation:)
        allow(AnswerComposition::Composer).to receive(:call).and_return(build(:answer, :abort_jailbreak_guardrails, question:))

        expect { described_class.new.perform(question.id) }
          .to change { user.reload.bannable_action_count }.by(1)
      end
    end

    context "when the question has already been answered" do
      let(:question) { create(:question, :with_answer) }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Question #{question.id} has already been answered")

        expect { described_class.new.perform(question.id) }
          .not_to change(Answer, :count)
      end
    end

    context "when the question does not exist" do
      it "logs a warning" do
        question_id = 999
        expect(described_class.logger)
          .to receive(:warn)
          .with("No question found for #{question_id}")

        expect { described_class.new.perform(question_id) }
          .not_to change(Answer, :count)
      end
    end

    context "when a timed out answer exists before RAG completion returns" do
      before do
        allow(AnswerComposition::Composer).to receive(:call) do
          # ensure a uniqueness conflict
          create(:answer, question:)
          returned_answer
        end
      end

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Already an answer created for #{question.id}")

        described_class.new.perform(question.id)
      end
    end
  end
end
