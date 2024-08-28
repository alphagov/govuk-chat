module PasswordlessRequestHelpers
  shared_context "when signed in" do
    let(:user) { create(:early_access_user) }
    before { sign_in_early_access_user(user) }
  end

  def sign_in_early_access_user(early_access_user)
    session = create(:passwordless_session, authenticatable: early_access_user)

    magic_link = magic_link_path(session.to_param, session.token)

    get(magic_link)
    follow_redirect!
  end
end
