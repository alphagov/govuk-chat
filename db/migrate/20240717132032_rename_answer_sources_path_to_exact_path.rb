class RenameAnswerSourcesPathToExactPath < ActiveRecord::Migration[7.1]
  def change
    rename_column :answer_sources, :path, :exact_path
  end
end
