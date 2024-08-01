class CreateSettingsAudits < ActiveRecord::Migration[7.1]
  def change
    create_table :settings_audits, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: { on_delete: :nullify }
      t.string :action, null: false
      t.string :author_comment

      t.timestamps
    end

    add_index(:settings_audits, :created_at)
  end
end
