require "mail_recipient_interceptor"

if ENV["EMAIL_ADDRESS_OVERRIDE"]
  ActionMailer::Base.register_interceptor(MailRecipientInterceptor)
end
