class AddTitleToAnswerSources < ActiveRecord::Migration[7.1]
  def change
    add_column :answer_sources, :title, :string
  end
end
