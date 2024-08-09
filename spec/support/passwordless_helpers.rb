module PasswordlessHelpers
  def passwordless_sign_in(resource)
    session = Passwordless::Session.create!(authenticatable: resource)

    magic_link = magic_link_path(session.to_param, session.token)

    get(magic_link)
    follow_redirect!
  end
end
