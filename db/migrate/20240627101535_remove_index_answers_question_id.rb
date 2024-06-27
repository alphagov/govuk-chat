class RemoveIndexAnswersQuestionId < ActiveRecord::Migration[7.1]
  def change
    remove_index :answers, :question_id
  end
end
