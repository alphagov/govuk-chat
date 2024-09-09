class EarlyAccessAuthMailer < ApplicationMailer
  def access_granted(session)
    @magic_link = magic_link_url(session.to_param, session.token)
    @token = session.authenticatable.unsubscribe_token
    @id = session.authenticatable.id
    view_mail(template_id, to: session.authenticatable.email, subject: "You can now access GOV.UK Chat")
  end

  def waitlist(user)
    view_mail(template_id, to: user.email, subject: "Thanks for joining the waitlist")
  end
end
