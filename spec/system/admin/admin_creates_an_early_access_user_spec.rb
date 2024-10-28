RSpec.describe "Admin user creates an early access user" do
  scenario do
    given_i_am_an_admin
    and_i_visit_the_early_access_users_index_page
    and_i_click_on_add_user
    and_i_fill_in_the_users_email_address
    then_i_see_the_user_details
  end

  def and_i_visit_the_early_access_users_index_page
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
end
