class AddQuestionRoutingConfidenceScoreToAnswers < ActiveRecord::Migration[7.1]
  def change
    add_column :answers, :question_routing_confidence_score, :float, null: true
  end
end
