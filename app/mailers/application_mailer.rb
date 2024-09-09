class ApplicationMailer < Mail::Notify::Mailer
  default from: "govuk-chat-beta@digital.cabinet-office.gov.uk"

  def template_id
    @template_id = ENV.fetch("GOVUK_NOTIFY_TEMPLATE_ID", "fake-test-template-id")
  end

  def view_mail(template_id, options)
    options[:reply_to_id] = ENV["GOVUK_NOTIFY_REPLY_TO_ID"] unless options[:reply_to_id]
    super(template_id, options)
  end
end
