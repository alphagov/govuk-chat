class FixMisspellingOnHeadingHierarchy < ActiveRecord::Migration[8.0]
  def change
    rename_column :answer_source_chunks, :heading_hierachy, :heading_hierarchy
  end
end
