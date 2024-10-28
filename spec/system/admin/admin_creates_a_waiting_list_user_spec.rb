RSpec.describe "Admin user creates a waiting list user" do
  scenario do
    given_i_am_an_admin
    and_i_visit_the_waiting_list_users_index_page
    and_i_click_on_add_user
    and_i_fill_in_the_users_details
    then_i_see_the_user_details
  end

  def and_i_visit_the_waiting_list_users_index_page
    visit admin_waiting_list_users_path
  end

  def and_i_click_on_add_user
    click_on "Add user"
  end

  def and_i_fill_in_the_users_details
    @email = "test@email.com"
    fill_in "Email address", with: @email

    @user_description = "I own a business or am self-employed"
    select @user_description

    @reason_for_visit = "To find a specific answer, like when the next bank holiday is"
    select @reason_for_visit

    click_button "Submit"
  end

  def then_i_see_the_user_details
    expect(page)
      .to have_content("User details")
      .and have_content(@email)
      .and have_content(@user_description)
      .and have_content(@reason_for_visit)
  end
end
