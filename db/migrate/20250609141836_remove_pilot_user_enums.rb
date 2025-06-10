class RemovePilotUserEnums < ActiveRecord::Migration[8.0]
  def up
    drop_enum :early_access_user_source
    drop_enum :deleted_early_access_user_deletion_type
    drop_enum :waiting_list_users_source
    drop_enum :deleted_waiting_list_user_deletion_type
  end

  def down
    create_enum :early_access_user_source, %w[admin_added instant_signup admin_promoted delayed_signup]
    create_enum :deleted_early_access_user_deletion_type, %w[unsubscribe admin]
    create_enum :waiting_list_users_source, %w[admin_added insufficient_instant_places]
    create_enum :deleted_waiting_list_user_deletion_type, %w[unsubscribe admin promotion]
  end
end
