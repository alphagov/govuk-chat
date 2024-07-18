class AddBasePathToAnswerSources < ActiveRecord::Migration[7.1]
  def change
    add_column :answer_sources, :base_path, :string
  end
end
