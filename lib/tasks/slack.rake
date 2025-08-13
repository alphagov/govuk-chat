namespace :slack do
  desc "Send a test message to the Slack channel"
  task :send_test_message, [:message] => :environment do |_, args|
    SlackPoster.test_message(args.fetch(:message, "Verifying we can post to Slack ✅"))
  end
end
