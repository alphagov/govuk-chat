class CreateBigqueryExports < ActiveRecord::Migration[7.2]
  def change
    create_table :bigquery_exports, id: :uuid do |t|
      t.datetime :exported_until, null: false

      t.timestamps
    end
    add_index :bigquery_exports, :exported_until, unique: true
  end
end
