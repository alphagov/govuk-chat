class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings, id: :uuid do |t|
      t.integer  :singleton_guard, default: 0
      t.integer :instant_access_places, default: 0
      t.integer :delayed_access_places, default: 0
      t.boolean :sign_up_enabled, default: false

      t.timestamps
    end
    add_index(:settings, :singleton_guard, unique: true)
  end
end
