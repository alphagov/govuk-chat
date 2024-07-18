class AddHeadingToAnswerSource < ActiveRecord::Migration[7.1]
  def change
    add_column :answer_sources, :heading, :string, null: true
  end
end
