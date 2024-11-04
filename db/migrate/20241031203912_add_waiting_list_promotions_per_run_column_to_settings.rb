class AddWaitingListPromotionsPerRunColumnToSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :settings,
               :waiting_list_promotions_per_run,
               :integer,
               default: 25,
               null: false
  end
end
