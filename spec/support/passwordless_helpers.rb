module PasswordlessHelpers
  def passwordless_sign_in(resource)
    session = Passwordless::Session.create!(authenticatable: resource)

    magic_link = sign_in_confirm_path(session.to_param, session.token)

    get(magic_link)
    follow_redirect!
  end
end
