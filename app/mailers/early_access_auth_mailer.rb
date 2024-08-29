class EarlyAccessAuthMailer < ApplicationMailer
  def sign_in(session)
    @magic_link = magic_link_url(session.to_param, session.token)
    view_mail(template_id, to: session.authenticatable.email, subject: "Sign in")
  end

  def waitlist(user)
    view_mail(template_id, to: user.email, subject: "Thanks for joining the waitlist")
  end

  def waitlist_promoted(session)
    @session_timeout_days = 30
    @magic_link_timeout_hours = 24
    @magic_link = magic_link_url(session.to_param, session.token)
    view_mail(template_id, to: session.authenticatable.email, subject: "You can now access GOV.UK Chat")
  end
end
