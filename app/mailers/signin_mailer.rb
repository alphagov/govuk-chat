class SigninMailer
  include Rails.application.routes.url_helpers
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
      Hello #{to}

      Welcome to GOV.UK Chat

      You can use the link below to start chatting. And you
      can always generate a new link when you need to access it again.
      #{magic_link}
    BODY
  end

  def magic_link
    url = sign_in_confirm_url(session.to_param, session.token)
    "[Start chatting](#{url})"
  end

  def to
    session.authenticatable.email
  end

  attr_reader :session

  delegate :token, to: :session
end
