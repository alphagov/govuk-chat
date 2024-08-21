class AddOnboardingCompletedToEarlyAccessUser < ActiveRecord::Migration[7.2]
  def change
    add_column :early_access_users, :onboarding_completed, :boolean, default: false, null: false
  end
end
