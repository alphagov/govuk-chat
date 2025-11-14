class AddCancelledMessageToAnswer < ActiveRecord::Migration[8.0]
  def change
    add_column :answers, :cancelled_message, :string
    add_column :answers, :cancelled, :boolean, default: false, null: false
  end
end
