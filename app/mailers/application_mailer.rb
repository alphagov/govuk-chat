class ApplicationMailer < Mail::Notify::Mailer
  default from: "govuk-chat-beta@digital.cabinet-office.gov.uk"

  def template
    @template = ENV.fetch("GOVUK_NOTIFY_TEMPLATE_ID", "fake-test-template-id")
  end
end
