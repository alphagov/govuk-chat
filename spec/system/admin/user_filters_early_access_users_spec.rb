RSpec.describe "Admin user filters early access users" do
  scenario do
    given_i_am_an_admin
    and_there_are_early_access_users

    when_i_visit_the_admin_area
    and_i_browse_to_the_early_access_users_section
    then_i_see_all_the_users

    when_i_reorder_the_users
    then_i_see_the_ordering_has_changed
  end

  def and_there_are_early_access_users
    create(:early_access_user, email: "alice@example.com", last_login_at: 1.minute.ago)
    create(:early_access_user, email: "betty@example.com", last_login_at: nil)
    create(:early_access_user, email: "clive@example.com", last_login_at: 1.hour.ago)
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_early_access_users_section
    click_link "Early access users"
  end

  def then_i_see_all_the_users
    within(".govuk-table") do
      expect(page).to have_content(/alice@example\.com.*clive@example\.com.*betty@example\.com/)
    end
  end

  def when_i_reorder_the_users
    click_link "Email"
  end

  def then_i_see_the_ordering_has_changed
    within(".govuk-table") do
      expect(page).to have_content(/alice@example\.com.*betty@example\.com.*clive@example\.com/)
    end
  end
end
