RSpec.describe "rake data_retention tasks" do
  describe "data_retention:delete_old_questions" do
    let(:task_name) { "data_retention:delete_old_questions" }

    before do
      Rake::Task[task_name].reenable
    end

    it "deletes the question, its answer and its answers sources when the question was asked over 3 months ago" do
      answer = build(:answer, :with_sources)
      question = create(:question, created_at: (3.months.ago - 1.day), answer:)
      create(:question, created_at: (3.months.ago + 1.day), conversation: question.conversation)

      expect { Rake::Task[task_name].invoke }
        .to change(Question, :count).by(-1)
        .and change(Answer, :count).by(-1)
        .and change(AnswerSource, :count).by(-2)
        .and change(Conversation, :count).by(0)
        .and output("\"1 question deleted\"\n\"0 conversations deleted\"\n").to_stdout
    end

    it "deletes the conversation if all its questions were asked over 3 months ago" do
      conversation = build(:conversation)
      create(:question, created_at: (3.months.ago - 1.day), conversation:)
      create(:question, created_at: (3.months.ago - 1.day), conversation:)

      expect { Rake::Task[task_name].invoke }
        .to change(Question, :count).by(-2)
        .and change(Conversation, :count).by(-1)
        .and output("\"2 questions deleted\"\n\"1 conversation deleted\"\n").to_stdout
    end
  end
end
