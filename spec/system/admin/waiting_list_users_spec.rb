RSpec.describe "Admin user waiting list users functionality" do
  scenario "admin creates a waiting list user" do
    given_i_am_an_admin
    when_i_visit_the_waiting_list_users_index_page
    and_i_click_on_add_user
    and_i_fill_in_the_users_details
    then_i_see_the_user_details
  end

  scenario "admin updates a waiting list user" do
    given_i_am_an_admin
    and_there_is_a_waiting_list_user
    when_i_visit_the_waiting_list_users_page
    and_i_edit_the_users_reason_for_visit
    then_i_see_the_new_reason_for_visit
  end

  scenario "admin deletes a waiting list user" do
    given_i_am_an_admin
    and_there_is_a_waiting_list_user
    when_i_visit_the_waiting_list_users_page
    and_delete_the_user
    then_i_see_the_user_is_deleted
  end

  scenario "admin promotes waiting list user" do
    given_i_am_an_admin
    and_there_is_a_waiting_list_user
    when_i_visit_the_waiting_list_users_page
    and_i_promote_the_user
    then_i_see_the_user_is_promoted
  end

  def when_i_visit_the_waiting_list_users_index_page
    visit admin_waiting_list_users_path
  end

  def and_i_click_on_add_user
    click_on "Add user"
  end

  def and_i_fill_in_the_users_details
    @email = "test@email.com"
    fill_in "Email address", with: @email

    @user_description = Rails.configuration.pilot_user_research_questions.dig(:user_description, :options, 0, :text)
    select @user_description

    click_button "Submit"
  end

  def then_i_see_the_user_details
    expect(page)
      .to have_content("User details")
      .and have_content(@email)
      .and have_content(@user_description)
  end

  def and_there_is_a_waiting_list_user
    @user = create(:waiting_list_user, "business_owner_or_self_employed")
  end

  def when_i_visit_the_waiting_list_users_page
    visit admin_waiting_list_user_path(@user)
  end

  def and_i_edit_the_users_reason_for_visit
    click_on "Edit user"
    select "To figure out a process, like how to export goods"
  end

  def then_i_see_the_new_reason_for_visit
    expect(page).to have_content "To figure out a process, like how to export goods"
  end

  def and_delete_the_user
    click_link "Delete user"
    click_button "Yes, delete this user"
  end

  def then_i_see_the_user_is_deleted
    expect(page).to have_content("User deleted")
    expect(page).not_to have_content(@user.email)
  end

  def and_i_promote_the_user
    click_link("Promote to Early Access User")
    click_button("Yes, promote this user")
  end

  def then_i_see_the_user_is_promoted
    expect(page).to have_content("User promoted")
  end
end
