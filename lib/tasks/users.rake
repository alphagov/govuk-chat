namespace :users do
  desc "Promote batch of WaitingListUsers to be EarlyAccessUsers"
  task promote_waiting_list: :environment do
    settings = Settings.instance
    next puts "Not promoting while public access is disabled" unless settings.public_access_enabled?
    next puts "No delayed access places available" if settings.delayed_access_places.zero?
    next puts "Promotions per run set to zero" if settings.waiting_list_promotions_per_run.zero?

    users_to_notify = []
    max_batch_size = settings.waiting_list_promotions_per_run
    settings.with_lock do
      max_promotions = [settings.delayed_access_places, max_batch_size].min
      WaitingListUser.users_to_promote(max_promotions).each do |waiting_list_user|
        users_to_notify << EarlyAccessUser.promote_waiting_list_user(waiting_list_user, :delayed_signup)
        settings.delayed_access_places -= 1
      end
      settings.save!
    end
    users_to_notify.each do |user|
      session = Passwordless::Session.create!(authenticatable: user)
      EarlyAccessAuthMailer.access_granted(session).deliver_now
    end
    puts "Promoted #{users_to_notify.length} user(s)"
  end
end
