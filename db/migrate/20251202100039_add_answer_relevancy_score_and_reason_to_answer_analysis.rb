class AddAnswerRelevancyScoreAndReasonToAnswerAnalysis < ActiveRecord::Migration[8.0]
  def change
    change_table :answer_analyses, bulk: true do |t|
      t.float :answer_relevancy_score
      t.string :answer_relevancy_reason
    end
  end
end
