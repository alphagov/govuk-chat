class ChangeDefaultAnswerStrategy < ActiveRecord::Migration[8.0]
  def change
    change_column_default(:questions,
                          :answer_strategy,
                          from: "openai_structured_answer",
                          to: nil)
  end
end
