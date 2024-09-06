class EarlyAccessAuthMailer < ApplicationMailer
  def sign_in(session)
    @magic_link = magic_link_url(session.to_param, session.token)
    view_mail(template_id, to: session.authenticatable.email, subject: "Sign in")
  end

  def waitlist(user)
    view_mail(template_id, to: user.email, subject: "Thanks for joining the waitlist")
  end

  def access_granted(session)
    @magic_link = magic_link_url(session.to_param, session.token)
    @token = session.authenticatable.revoke_access_token
    @id = session.authenticatable.id
    view_mail(template_id, to: session.authenticatable.email, subject: "You can now access GOV.UK Chat")
  end
end
