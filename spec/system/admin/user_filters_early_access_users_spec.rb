RSpec.describe "Admin user filters early access users" do
  scenario do
    given_i_am_an_admin
    and_there_are_early_access_users

    when_i_visit_the_admin_area
    and_i_browse_to_the_early_access_users_section
    then_i_see_all_the_users

    when_i_reorder_the_users
    then_i_see_the_ordering_has_changed

    when_i_search_by_email
    then_i_see_the_users_relevant_to_my_search

    when_i_clear_the_filters
    then_i_see_all_the_users

    when_i_filter_by_source
    then_i_see_the_admin_added_user

    when_i_clear_the_filters
    and_i_filter_by_revoked
    then_i_see_the_revoked_user
  end

  def and_there_are_early_access_users
    create(:early_access_user, email: "alice@example.com", last_login_at: 1.minute.ago, source: :instant_signup)
    create(:early_access_user, email: "betty@example.com", last_login_at: nil, source: :admin_added, revoked_at: nil)
    create(:early_access_user, email: "clive@example.com", last_login_at: 1.hour.ago, source: :instant_signup, revoked_at: 1.minute.ago)
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

  def when_i_search_by_email
    fill_in "Email address", with: "clive"
    click_button "Filter"
  end

  def then_i_see_the_users_relevant_to_my_search
    within(".govuk-table") do
      expect(page).to have_content("clive@example.com")
      expect(page).not_to have_content("alice@example.com")
      expect(page).not_to have_content("betty@example.com")
    end
  end

  def when_i_clear_the_filters
    click_on "Clear all filters"
  end

  def when_i_filter_by_source
    select "Admin added", from: "source"
    click_button "Filter"
  end

  def and_i_filter_by_revoked
    select "Revoked", from: "revoked"
    click_button "Filter"
  end

  def then_i_see_the_admin_added_user
    within(".govuk-table") do
      expect(page).to have_content("betty@example.com")
      expect(page).not_to have_content("alice@example.com")
      expect(page).not_to have_content("clive@example.com")
    end
  end

  def then_i_see_the_revoked_user
    within(".govuk-table") do
      expect(page).to have_content("clive@example.com")
      expect(page).not_to have_content("alice@example.com")
      expect(page).not_to have_content("betty@example.com")
    end
  end
end
