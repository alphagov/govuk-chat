class AddMaxWaitingListPlacesToSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :settings, :max_waiting_list_places, :integer, default: 1000, null: false
  end
end
