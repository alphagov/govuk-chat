namespace :notify do
  desc "Send an email notification"
  task :send_email, [:email_address] => :environment do |_, args|
    to = ENV.fetch("EMAIL_ADDRESS_OVERRIDE", args.email_address)
    raise "Missing email address" if to.blank?

    template = ENV.fetch("GOVUK_NOTIFY_TEMPLATE_ID")

    params = {
      to:,
      subject: ENV.fetch("SUBJECT", "Test email notification"),
      body: ENV.fetch("BODY", "Test email notification"),
    }

    ApplicationMailer.view_mail(template, **params).deliver_now
  end
end
