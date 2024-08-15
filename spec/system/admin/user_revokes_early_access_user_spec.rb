RSpec.describe "Admin user revokes early access user" do
  scenario do
    given_i_am_an_admin
    and_there_is_an_early_access_user

    when_i_view_the_user
    then_i_see_the_user_is_not_revoked

    when_i_revoke_the_users_access
    then_i_see_the_user_is_revoked

    when_i_restore_the_users_access
    then_i_see_the_user_is_not_revoked
  end

  def and_there_is_an_early_access_user
    @user = create(:early_access_user, revoked_at: nil)
  end

  def when_i_view_the_user
    visit admin_early_access_user_path(@user)
  end

  def then_i_see_the_user_is_not_revoked
    expect(page).to have_content(/Revoked\?.*No/)
  end

  def when_i_revoke_the_users_access
    click_link("Revoke access")

    freeze_time do
      fill_in "Reason for revoking access", with: "Asking too many questions"
      click_button("Submit")
    end
  end

  def then_i_see_the_user_is_revoked
    expect(page)
      .to have_content(/Revoked on.*#{Time.zone.now.to_fs(:time_and_date)}/)
      .and have_content("Asking too many questions")
  end

  def when_i_restore_the_users_access
    click_button("Restore access")
  end
end
