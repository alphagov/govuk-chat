namespace :slack do
  desc "Test shadow ban notification"
  task test_shadow_ban_notification: :environment do
    user = EarlyAccessUser.last

    raise "Couldn't find user" if user.nil?

    SlackPoster.shadow_ban_notification(user.id)
  end
end
