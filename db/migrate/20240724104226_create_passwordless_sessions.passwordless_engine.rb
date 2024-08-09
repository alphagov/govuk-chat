# frozen_string_literal: true

# This migration comes from passwordless_engine (originally 20171104221735)
class CreatePasswordlessSessions < ActiveRecord::Migration[7.1]
  def change
    create_table(:passwordless_sessions, id: :uuid) do |t|
      t.belongs_to(
        :authenticatable,
        polymorphic: true,
        type: :uuid,
        index: { name: "authenticatable" },
      )

      t.datetime(:timeout_at, null: false)
      t.datetime(:expires_at, null: false)
      t.datetime(:claimed_at)
      t.string(:token_digest, null: false)
      t.uuid(:identifier, null: false, index: { unique: true })

      t.timestamps
    end
  end
end
