class MailRecipientInterceptor
  def self.delivering_email(message)
    body_prefix = "Intended recipient(s): #{message.to.join(', ')}\n\n"

    message.personalisation[:body] = message.personalisation[:body].prepend(body_prefix)
    message.to = ENV.fetch("EMAIL_ADDRESS_OVERRIDE")
  end
end
