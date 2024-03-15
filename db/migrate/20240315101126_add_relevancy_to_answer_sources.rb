class AddRelevancyToAnswerSources < ActiveRecord::Migration[7.1]
  # relevancy will be in ascending order, 0 being the most relevant, as Rails sorts
  # the records in ascending order by default
  def change
    add_column :answer_sources, :relevancy, :integer
    remove_index :answer_sources, :answer_id
    add_index :answer_sources, %i[answer_id relevancy], unique: true
  end
end
