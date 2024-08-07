class EarlyAccessAuthMailer < ApplicationMailer
  def sign_in(session)
    @magic_link = magic_link_url(session.to_param, session.token)
    view_mail(template_id, to: session.authenticatable.email, subject: "Sign in")
  end
end
