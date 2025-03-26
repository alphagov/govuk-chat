namespace :notify do
  desc "Send an email notification"
  task :send_email, [:email_address] => :environment do |_, args|
    raise "Missing email address" if args.email_address.blank?

    # This should be a basic template with `subject` and `body` placeholders
    template = ENV.fetch("GOVUK_NOTIFY_TEMPLATE_ID")

    params = {
      to: args.email_address,
      personalisation: {
        subject: ENV.fetch("SUBJECT", "Test email notification"),
        body: ENV.fetch("BODY", "Test email notification"),
      },
    }

    ApplicationMailer.template_mail(template, **params).deliver_now
  end
end
