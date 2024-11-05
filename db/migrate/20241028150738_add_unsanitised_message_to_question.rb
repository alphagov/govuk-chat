class AddUnsanitisedMessageToQuestion < ActiveRecord::Migration[7.2]
  def change
    add_column :questions, :unsanitised_message, :string, null: true
  end
end
