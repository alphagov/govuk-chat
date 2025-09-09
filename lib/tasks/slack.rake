namespace :slack do
  desc "Send a test message to the Slack channel"
  task :send_test_message, [:message] => :environment do |_, args|
    SlackPoster.test_message(args.fetch(:message, "Verifying we can post to Slack ✅"))
  end

  desc "Post the Chat activity for the previous day to the Slack channel"
  task :send_previous_days_activity, [:message] => :environment do
    SlackPoster.previous_days_api_activity
  end
end
