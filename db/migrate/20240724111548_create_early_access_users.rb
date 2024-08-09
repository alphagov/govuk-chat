class CreateEarlyAccessUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :early_access_users, id: :uuid do |t|
      t.citext :email, null: false, index: { unique: true }
      t.datetime :last_login_at, null: true

      t.timestamps
    end
  end
end
