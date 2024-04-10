class CreateBasePathVersion < ActiveRecord::Migration[7.1]
  def change
    create_table :base_path_versions, id: :uuid do |t|
      t.string "base_path", null: false, index: { unique: true }
      t.bigint "payload_version", default: 0, null: false
      t.timestamps
    end
  end
end
