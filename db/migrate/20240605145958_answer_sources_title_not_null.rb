class AnswerSourcesTitleNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :answer_sources, :title, false
  end
end
