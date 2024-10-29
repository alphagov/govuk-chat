RSpec.describe "Admin user early access users functionality" do
  scenario "admin creates an early access user" do
    given_i_am_an_admin
    when_i_visit_the_early_access_users_index_page
    and_i_click_on_add_user
    and_i_fill_in_the_users_email_address
    then_i_see_the_user_details
  end

  scenario "admin updates an early access user" do
    given_i_am_an_admin
    and_there_is_an_early_access_user
    when_i_visit_an_early_access_user_page
    and_i_update_the_user_question_limit
    then_i_see_the_question_limit_updated
  end

  scenario "admin deletes an early access user" do
    given_i_am_an_admin
    and_there_is_an_early_access_user
    when_i_visit_an_early_access_user_page
    and_i_delete_the_user
    then_i_see_the_user_is_deleted
  end

  scenario "admin revokes and restores an early access user's access" do
    given_i_am_an_admin
    and_there_is_an_early_access_user
    when_i_visit_an_early_access_user_page
    and_i_revoke_the_users_access
    then_i_see_the_user_is_revoked

    when_i_restore_the_users_access
    then_i_see_the_user_is_not_revoked
  end

  def when_i_visit_the_early_access_users_index_page
    visit admin_early_access_users_path
  end

  def and_i_click_on_add_user
    click_on "Add user"
  end

  def and_i_fill_in_the_users_email_address
    @email = "test@email.com"
    fill_in "Email address", with: @email
    click_button "Submit"
  end

  def then_i_see_the_user_details
    expect(page)
      .to have_content("User details")
      .and have_content(@email)
  end

  def and_there_is_an_early_access_user
    @user = create(:early_access_user)
  end

  def when_i_visit_an_early_access_user_page
    visit admin_early_access_user_path(@user)
  end

  def and_i_update_the_user_question_limit
    click_link "Edit user"
    fill_in "Question limit", with: 500
    click_button "Submit"
  end

  def then_i_see_the_question_limit_updated
    expect(page)
      .to have_content("Question limit")
      .and have_content("500")
  end

  def and_i_delete_the_user
    visit admin_early_access_user_path(@user)
    click_link "Delete user"
    click_button "Yes, delete this user"
  end

  def then_i_see_the_user_is_deleted
    expect(page).to have_content("User deleted")
    expect(page).not_to have_content(@user.email)
  end

  def and_i_revoke_the_users_access
    click_on "Revoke access"

    freeze_time do
      @revoked_time = Time.current
      fill_in "Reason for revoking access", with: "Asking too many questions"
      click_button("Submit")
    end
  end

  def then_i_see_the_user_is_revoked
    expect(page)
      .to have_content(/Revoked on.*#{@revoked_time.to_fs(:time_and_date)}/)
      .and have_content("Asking too many questions")
  end

  def when_i_restore_the_users_access
    click_button("Restore access")
  end

  def then_i_see_the_user_is_not_revoked
    expect(page).to have_content(/Revoked\?.*No/)
  end
end
