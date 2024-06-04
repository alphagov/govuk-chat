namespace :data_retention do
  desc "Delete questions older than 3 months & all conversations with no questions"
  task delete_old_questions: :environment do
    question_count = Question.where("created_at < ?", 3.months.ago).delete_all
    p "#{question_count} #{'question'.pluralize(question_count)} deleted"

    conversation_count = Conversation.where.missing(:questions).delete_all
    p "#{conversation_count} #{'conversation'.pluralize(conversation_count)} deleted"
  end
end
