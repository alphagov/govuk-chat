class AddPreviousSignUpDeniedToEarlyAccessUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :early_access_users, :previous_sign_up_denied, :boolean, null: false, default: false
  end
end
