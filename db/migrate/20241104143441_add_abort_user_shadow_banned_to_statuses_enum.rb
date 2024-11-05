class AddAbortUserShadowBannedToStatusesEnum < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :status, "abort_user_shadow_banned"
  end
end
