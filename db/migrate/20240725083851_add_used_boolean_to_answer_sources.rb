class AddUsedBooleanToAnswerSources < ActiveRecord::Migration[7.1]
  def change
    add_column :answer_sources, :used, :boolean, default: true
  end
end
