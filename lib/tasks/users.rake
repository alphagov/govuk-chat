namespace :users do
  desc "Promote batch of WaitingListUsers to be EarlyAccessUsers"
  task promote_waiting_list: :environment do
    users_to_notify = []
    settings = Settings.instance
    max_promotions = [settings.delayed_access_places, 50].min
    settings.with_lock do
      ActiveRecord::Base.transaction do
        WaitingListUser.limit(max_promotions).each do |waiting_list_user|
          EarlyAccessUser.promote_waiting_list_user(waiting_list_user) do |early_access_user|
            users_to_notify << early_access_user
            settings.delayed_access_places -= 1
          end
        end
        settings.save!
      end
    end
  end
end
