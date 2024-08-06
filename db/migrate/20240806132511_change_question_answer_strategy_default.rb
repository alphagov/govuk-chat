class ChangeQuestionAnswerStrategyDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default(:questions, :answer_strategy, from: nil, to: "openai_structured_answer")
  end
end
