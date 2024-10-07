RSpec.describe "Admin user views metrics", :js do
  scenario do
    given_i_am_an_admin
    and_there_has_been_activity
    when_i_visit_the_admin_area
    and_i_browse_to_the_metrics_section
    then_i_can_see_this_activity
  end

  def and_there_has_been_activity
    create_list(:early_access_user, 3, created_at: 2.days.ago)
    create_list(:waiting_list_user, 2)
    create_list(:question, 2)
    create_list(:answer_feedback, 3, created_at: 1.day.ago)
    create_list(:answer, 3, created_at: 3.days.ago, status: :abort_llm_cannot_answer)
    create_list(:answer, 5, created_at: 4.days.ago, status: :error_timeout)
    create_list(:answer, 2, created_at: 1.day.ago, question_routing_label: :genuine_rag)
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_metrics_section
    click_link "Metrics"
  end

  def then_i_can_see_this_activity
    # We're relying on the rendering of a successful chart results in a canvas
    # element, unclear how to assert correct chart
    expect(page).to have_selector("#early-access-users canvas")
    expect(page).to have_selector("#waiting-list-users canvas")
    expect(page).to have_selector("#conversations canvas")
    expect(page).to have_selector("#questions canvas")
    expect(page).to have_selector("#answer-feedback canvas")
    expect(page).to have_selector("#answers-with-abort-status canvas")
    expect(page).to have_selector("#answers-with-error-status canvas")
    expect(page).to have_selector("#question-routing-labels canvas")
  end
end
