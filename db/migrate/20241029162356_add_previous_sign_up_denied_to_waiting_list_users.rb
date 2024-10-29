class AddPreviousSignUpDeniedToWaitingListUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :waiting_list_users, :previous_sign_up_denied, :boolean, null: false, default: false
  end
end
