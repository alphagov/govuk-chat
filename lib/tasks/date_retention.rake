namespace :data_retention do
  desc "Delete questions older than 1 year & all conversations with no questions"
  task delete_old_questions: :environment do
    question_count = Question.where("created_at < ?", 1.year.ago).delete_all
    p "#{question_count} #{'question'.pluralize(question_count)} and associated data deleted"

    conversation_count = Conversation.where.missing(:questions).delete_all
    p "#{conversation_count} #{'conversation'.pluralize(conversation_count)} deleted"
  end
end
