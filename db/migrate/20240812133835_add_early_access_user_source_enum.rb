class AddEarlyAccessUserSourceEnum < ActiveRecord::Migration[7.1]
  def change
    create_enum "early_access_user_source", %w[admin_added instant_signup]
  end
end
