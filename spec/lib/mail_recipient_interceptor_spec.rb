RSpec.describe MailRecipientInterceptor do
  let(:override_email) { "override@chat.gov.uk" }
  let(:notify_template_id) { "12345" }

  before { ActionMailer::Base.register_interceptor(described_class) }
  after { ActionMailer::Base.unregister_interceptor(described_class) }

  around do |example|
    ClimateControl.modify(EMAIL_ADDRESS_OVERRIDE: override_email) { example.run }
  end

  it "overrides the 'to' field of the message" do
    send_email
    expect(last_email_sent.to).to eq([override_email])
  end

  it "prefixes the body with the intended recipients" do
    send_email(to: "a@gmail.com, b@gmail.com", body: "Message")
    expect(last_email_sent.body.raw_source)
      .to eq("Intended recipient(s): a@gmail.com, b@gmail.com\n\nMessage")
  end

  def send_email(to: "user@gmail.com", subject: "Subject", body: "Body")
    ApplicationMailer.view_mail(
      notify_template_id,
      { to:, subject:, body: },
    ).deliver_now

    ActionMailer::Base.deliveries.last
  end

  def last_email_sent
    ActionMailer::Base.deliveries.last
  end
end
