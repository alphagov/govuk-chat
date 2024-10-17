class RemoveNotGovukContentRecordsFromQuestionRoutingLabelEnum < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
    ALTER TYPE question_routing_label RENAME TO question_routing_label_old;

    CREATE TYPE question_routing_label AS ENUM(
                                          'about_mps',
                                          'advice_opinions_predictions',
                                          'character_fun',
                                          'genuine_rag',
                                          'gov_transparency',
                                          'greetings',
                                          'harmful_vulgar_controversy',
                                          'multi_questions',
                                          'negative_acknowledgement',
                                          'non_english',
                                          'personal_info',
                                          'positive_acknowledgement',
                                          'vague_acronym_grammar');

    ALTER TABLE answers ALTER COLUMN question_routing_label TYPE question_routing_label USING question_routing_label::text::question_routing_label;

    DROP TYPE question_routing_label_old;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
