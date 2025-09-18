class DefaultForHeadingHierarchy < ActiveRecord::Migration[8.0]
  def up
    change_table :answer_source_chunks, bulk: true do |t|
      t.change :heading_hierarchy, :string, array: true, default: [], null: false
    end
  end

  def down
    change_table :answer_source_chunks, bulk: true do |t|
      t.change :heading_hierarchy, :string, array: true, default: nil, null: true
    end
  end
end
