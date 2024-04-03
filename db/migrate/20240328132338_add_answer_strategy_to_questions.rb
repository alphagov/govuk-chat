class AddAnswerStrategyToQuestions < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/NotNullColumn
  def change
    add_column :questions, :answer_strategy, :string, null: false
  end
  # rubocop:enable Rails/NotNullColumn
end
