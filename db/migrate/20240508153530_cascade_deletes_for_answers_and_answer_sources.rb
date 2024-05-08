class CascadeDeletesForAnswersAndAnswerSources < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key(:answers, :questions)
    remove_foreign_key(:answer_sources, :answers)
    add_foreign_key(:answers, :questions, on_delete: :cascade)
    add_foreign_key(:answer_sources, :answers, on_delete: :cascade)
  end
end
