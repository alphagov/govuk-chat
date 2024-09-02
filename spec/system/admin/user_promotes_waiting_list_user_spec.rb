RSpec.describe "Admin user promotes waiting list user" do
  scenario do
    given_i_am_an_admin
    and_there_is_a_waiting_list_user

    when_i_view_the_user
    and_i_promote_the_user
    then_i_see_the_user_is_promoted
  end

  def and_there_is_a_waiting_list_user
    @user = create(:waiting_list_user)
  end

  def when_i_view_the_user
    visit admin_waiting_list_user_path(@user)
  end

  def and_i_promote_the_user
    click_link("Promote to Early Access User")
    click_button("Yes, promote this user")
  end

  def then_i_see_the_user_is_promoted
    expect(page).to have_content("User promoted")
  end
end
