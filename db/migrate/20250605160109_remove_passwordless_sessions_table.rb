class RemovePasswordlessSessionsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :passwordless_sessions
  end

  def down
    create_table :passwordless_sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :authenticatable_type
      t.uuid :authenticatable_id
      t.datetime :timeout_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :claimed_at
      t.string :token_digest, null: false
      t.uuid :identifier, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index %i[authenticatable_type authenticatable_id], name: "authenticatable"
      t.index :identifier, unique: true, name: "index_passwordless_sessions_on_identifier"
    end
  end
end
