class SigninMailer
  def self.call(...) = new(...).call

  def initialize(session)
    @session = session
  end

  def call
    template = ENV.fetch("GOVUK_NOTIFY_TEMPLATE_ID")
    params = {
      to:,
      subject: "GOV.UK Chat login link",
      body:,
    }

    ApplicationMailer.view_mail(template, **params)
  end

private

  def body
    <<~BODY
      To access GOV.UK chat please provide the following code. #{token}

      Alternatively you can access GOV.UK Chat using this link
      #{magic_link}
    BODY
  end

  def magic_link
    Passwordless.context.url_for(
      session,
      action: "confirm",
      id: session.to_param,
      token:,
    )
  end

  def to
    session.authenticatable.email
  end

  attr_reader :session

  delegate :token, to: :session
end
