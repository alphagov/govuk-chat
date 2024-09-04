RSpec.describe "Admin user deletes early access user" do
  scenario do
    given_i_am_an_admin
    and_there_is_an_early_access_user

    when_i_delete_the_user
    then_i_see_the_user_is_deleted
  end

  def and_there_is_an_early_access_user
    @user = create(:early_access_user)
  end

  def when_i_delete_the_user
    visit admin_early_access_user_path(@user)
    click_link "Delete user"
    click_button "Yes, delete this user"
  end

  def then_i_see_the_user_is_deleted
    expect(page).to have_content("User deleted")
    expect(page).not_to have_content(@user.email)
  end
end
