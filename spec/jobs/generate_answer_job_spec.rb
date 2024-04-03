RSpec.describe GenerateAnswerJob do
  include ActiveJob::TestHelper
  let(:question) { create(:question, message: user_input) }
  let(:user_input) { "hello" }
  let(:chat_url) { "https://chat-api.example.com" }
  let(:returned_answer) { build :answer, :with_sources, question:, message: "Hello, how can I help you?" }

  before do
    allow(AnswerComposition::Composer).to receive(:call).and_return(returned_answer)
  end

  describe "#perform" do
    it "saves the answer and sources returned from the chat api" do
      expect { described_class.new.perform(question.id) }
        .to change(Answer, :count).by(1)
        .and change(AnswerSource, :count).by(2)
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
  end
end
