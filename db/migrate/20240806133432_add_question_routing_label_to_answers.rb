class AddQuestionRoutingLabelToAnswers < ActiveRecord::Migration[7.1]
  def change
    add_column :answers, :question_routing_label, :enum, enum_type: "question_routing_label", null: true
  end
end
