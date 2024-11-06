namespace :slack do
  desc "Test shadow ban notification"
  task test_shadow_ban_notification: :environment do
    SlackPoster.shadow_ban_notification(SecureRandom.uuid, test_mode: true)
  end
end
