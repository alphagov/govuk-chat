class AddSearchScoreAndWeightedScoreToAnswerSources < ActiveRecord::Migration[8.0]
  def change
    change_table :answer_sources, bulk: true do |t|
      t.float :search_score
      t.float :weighted_score
    end
  end
end
