RSpec.describe "Waiting list user unsubscribes" do
  scenario do
    given_i_have_signed_up_for_the_waiting_list
    when_i_unsubscribe
    then_my_user_is_deleted
    and_i_see_a_confirmation_page
  end

  def given_i_have_signed_up_for_the_waiting_list
    @user = create(:waiting_list_user)
  end

  def when_i_unsubscribe
    visit waiting_list_user_unsubscribe_path(@user.id, @user.unsubscribe_token)
  end

  def then_my_user_is_deleted
    expect(WaitingListUser.exists?(@user.id)).to be(false)
  end

  def and_i_see_a_confirmation_page
    expect(page).to have_content("You’ve opted out of GOV.UK Chat")
  end
end
