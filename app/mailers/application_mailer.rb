class ApplicationMailer < Mail::Notify::Mailer
  default from: "govuk-chat-beta@digital.cabinet-office.gov.uk"

  def template_id
    @template_id = ENV.fetch("GOVUK_NOTIFY_TEMPLATE_ID", "fake-test-template-id")
  end
end
