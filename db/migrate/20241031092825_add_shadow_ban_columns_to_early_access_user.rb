class AddShadowBanColumnsToEarlyAccessUser < ActiveRecord::Migration[7.2]
  def change
    change_table :early_access_users, bulk: true do |t|
      t.datetime :shadow_banned_at
      t.string :shadow_banned_reason
      t.integer :bannable_action_count, default: 0, null: false
      t.datetime :restored_at
      t.string :restored_reason
    end
  end
end
