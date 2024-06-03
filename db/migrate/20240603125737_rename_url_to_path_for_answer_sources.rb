class RenameUrlToPathForAnswerSources < ActiveRecord::Migration[7.1]
  def change
    rename_column :answer_sources, :url, :path
  end
end
