RSpec.describe "Admin user updates early user" do
  scenario do
    given_i_am_an_admin
    and_i_visit_an_early_access_user_page
    then_i_see_the_user_details

    when_i_update_the_user_question_limit
    then_i_see_the_question_limit_updated
  end

  def and_i_visit_an_early_access_user_page
    @user = create(:early_access_user)
    visit admin_early_access_user_path(@user)
  end

  def then_i_see_the_user_details
    expect(page)
      .to have_content("User details")
      .and have_content(@user.email)
  end

  def when_i_update_the_user_question_limit
    click_link "Edit user"
    fill_in "Question limit", with: 500
    click_button "Submit"
  end

  def then_i_see_the_question_limit_updated
    expect(page)
      .to have_content("Question limit")
      .and have_content("500")
  end
end
