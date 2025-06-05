class RemoveDeletedSettings < ActiveRecord::Migration[8.0]
  def up
    change_table :settings, bulk: true do |t|
      t.remove :instant_access_places
      t.remove :delayed_access_places
      t.remove :sign_up_enabled
      t.remove :max_waiting_list_places
      t.remove :waiting_list_promotions_per_run
    end
  end

  def down
    change_table :settings, bulk: true do |t|
      t.integer :instant_access_places, default: 0
      t.integer :delayed_access_places, default: 0
      t.boolean :sign_up_enabled, default: false
      t.integer :max_waiting_list_places, default: 1000, null: false
      t.integer :waiting_list_promotions_per_run, default: 25, null: false
    end
  end
end
