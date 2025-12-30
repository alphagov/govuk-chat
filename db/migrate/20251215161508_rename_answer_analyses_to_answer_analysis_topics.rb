class RenameAnswerAnalysesToAnswerAnalysisTopics < ActiveRecord::Migration[8.0]
  def change
    rename_table :answer_analyses, :answer_analysis_topics
  end
end
