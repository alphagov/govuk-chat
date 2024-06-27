class CreateUniqueIndexAnswersQuestionId < ActiveRecord::Migration[7.1]
  def change
    add_index :answers, :question_id, unique: true
  end
end
