class AddAdminPromotedSourceToWaitingListUsers < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :early_access_user_source, "admin_promoted"
  end
end
