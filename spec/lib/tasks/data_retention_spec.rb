RSpec.describe "rake data_retention tasks" do
  describe "data_retention:delete_old_questions" do
    let(:task_name) { "data_retention:delete_old_questions" }

    before do
      Rake::Task[task_name].reenable
    end

    it "deletes the question and it's associated data if the question was asked over 1 year ago" do
      answer = build(:answer, :with_sources)
      question = create(:question, created_at: (1.year.ago - 1.day), answer:)
      %i[
        coherence_run
        context_relevancy_run
        faithfulness_run
        answer_relevancy_run
        answer_analysis_topics
      ].each do |model|
        create(model, answer:)
      end
      create(:question, created_at: (1.year.ago + 1.day), conversation: question.conversation)

      expect { Rake::Task[task_name].invoke }
        .to change(Question, :count).by(-1)
        .and change(Answer, :count).by(-1)
        .and change(AnswerSource, :count).by(-2)
        .and change(AnswerAnalysis::CoherenceRun, :count).by(-1)
        .and change(AnswerAnalysis::ContextRelevancyRun, :count).by(-1)
        .and change(AnswerAnalysis::FaithfulnessRun, :count).by(-1)
        .and change(AnswerAnalysis::AnswerRelevancyRun, :count).by(-1)
        .and change(AnswerAnalysis::Topics, :count).by(-1)
        .and not_change(Conversation, :count)
        .and output("\"1 question and associated data deleted\"\n\"0 conversations deleted\"\n").to_stdout
    end

    it "deletes the conversation if all its questions were asked over 1 year ago" do
      conversation = build(:conversation)
      create(:question, created_at: (1.year.ago - 1.day), conversation:)
      create(:question, created_at: (1.year.ago - 1.day), conversation:)

      expect { Rake::Task[task_name].invoke }
        .to change(Question, :count).by(-2)
        .and change(Conversation, :count).by(-1)
        .and output("\"2 questions and associated data deleted\"\n\"1 conversation deleted\"\n").to_stdout
    end
  end
end
