class AnswerSourceAnswerIdIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :answer_sources, :answer_id
  end
end
