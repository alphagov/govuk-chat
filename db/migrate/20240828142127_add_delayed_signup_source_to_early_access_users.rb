class AddDelayedSignupSourceToEarlyAccessUsers < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :early_access_user_source, "delayed_signup"
  end
end
