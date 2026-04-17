class RemoveLegacyQuestionRoutingLabels < ActiveRecord::Migration[8.1]
  class Answer < ApplicationRecord; end
  class AnswerAnalysisAnswerRelevancyRun < ApplicationRecord; end

  def up
    Question.joins(:answer)
            .where(answer: { question_routing_label: %w[multi_questions personal_info vague_acronym_grammar] })
            .delete_all

    Conversation.where.missing(:questions).delete_all

    execute <<-SQL
    ALTER TYPE question_routing_label RENAME TO question_routing_label_old;

    CREATE TYPE question_routing_label AS ENUM(
                                          'about_chat',
                                          'about_mps',
                                          'advice_opinions_predictions',
                                          'character_fun',
                                          'genuine_rag',
                                          'gov_transparency',
                                          'greetings',
                                          'harmful_vulgar_controversy',
                                          'mental_health_crisis_signposting',
                                          'negative_acknowledgement',
                                          'non_english',
                                          'positive_acknowledgement',
                                          'requires_account_data',
                                          'unclear_intent');

    ALTER TABLE answers ALTER COLUMN question_routing_label TYPE question_routing_label USING question_routing_label::text::question_routing_label;

    DROP TYPE question_routing_label_old;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
