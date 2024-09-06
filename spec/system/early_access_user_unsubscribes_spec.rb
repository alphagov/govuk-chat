RSpec.describe "Early access user unsubscribes" do
  scenario do
    given_i_am_an_early_access_user
    when_i_unsubscribe
    then_my_user_is_deleted
    and_i_see_a_confirmation_page
  end

  def given_i_am_an_early_access_user
    @user = create(:early_access_user)
  end

  def when_i_unsubscribe
    visit early_access_user_unsubscribe_path(@user.id, @user.unsubscribe_access_token)
  end

  def then_my_user_is_deleted
    expect(EarlyAccessUser.exists?(@user.id)).to be(false)
  end

  def and_i_see_a_confirmation_page
    expect(page).to have_content("You’ve opted out of GOV.UK Chat")
      .and have_content("Thanks for helping to test GOV.UK Chat")
  end
end
