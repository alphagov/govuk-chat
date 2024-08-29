namespace :users do
  desc "Promote batch of WaitingListUsers to be EarlyAccessUsers"
  task promote_waiting_list: :environment do
    settings = Settings.instance
    if settings.delayed_access_places.zero?
      puts "No delayed access places available"
    else
      users_to_notify = []
      max_batch_size = Rails.configuration.early_access_users.max_waiting_list_promotions_per_run
      max_promotions = [settings.delayed_access_places, max_batch_size].min
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
      users_to_notify.each do |user|
        session = Passwordless::Session.create!(authenticatable: user)
        EarlyAccessAuthMailer.waitlist_promoted(session).deliver_now
      end
    end
  end
end
