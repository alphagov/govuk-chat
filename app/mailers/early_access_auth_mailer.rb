class EarlyAccessAuthMailer < ApplicationMailer
  def access_granted(session)
    @magic_link = magic_link_url(session.to_param, session.token)
    @id = session.authenticatable.id
    @token = session.authenticatable.unsubscribe_token
    @session_timeout_days = 30
    @magic_link_timeout_hours = 24
    view_mail(template_id, to: session.authenticatable.email, subject: "You can now access GOV.UK Chat")
  end

  def waitlist(user)
    @id = user.id
    @token = user.unsubscribe_token
    view_mail(template_id, to: user.email, subject: "You're on the waitlist for GOV.UK Chat")
  end
end
