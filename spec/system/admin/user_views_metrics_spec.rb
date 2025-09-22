RSpec.describe "Admin user views metrics", :js do
  scenario do
    given_i_am_an_admin
    and_there_has_been_activity
    when_i_visit_the_admin_area
    and_i_browse_to_the_metrics_section
    then_i_can_see_activity
    and_i_can_see_its_for_last_24_hours

    when_i_navigate_to_view_last_7_days
    then_i_can_see_activity
    and_i_can_see_its_for_last_7_days
  end

  def and_there_has_been_activity
    create_list(:question, 2)
    create_list(:answer_feedback, 1, created_at: 1.hour.ago)
    create_list(:answer, 2, :with_analysis, created_at: 6.hours.ago, status: :unanswerable_llm_cannot_answer)
    create_list(:answer, 3, created_at: 4.hours.ago, status: :error_timeout)
    create_list(:answer, 1, created_at: 20.hours.ago, question_routing_label: :genuine_rag)
    create_list(:answer,
                4,
                created_at: 15.hours.ago,
                answer_guardrails_status: :fail,
                answer_guardrails_failures: %w[guardrail_1 guardrail_2])
    create_list(:answer,
                2,
                created_at: 5.hours.ago,
                question_routing_guardrails_status: :fail,
                question_routing_guardrails_failures: %w[guardrail_1 guardrail_2])
  end

  def when_i_visit_the_admin_area
    visit admin_homepage_path
  end

  def and_i_browse_to_the_metrics_section
    click_link "Metrics"
  end

  def then_i_can_see_activity
    # We're relying on the rendering of a successful chart results in a canvas
    # element, unclear how to assert correct chart
    expect(page).to have_selector("#conversations canvas")
    expect(page).to have_selector("#questions canvas")
    expect(page).to have_selector("#answers-with-unanswerable-status canvas")
    expect(page).to have_selector("#answers-with-error-status canvas")
    expect(page).to have_selector("#question-routing-labels canvas")
    expect(page).to have_selector("#answer-guardrails-failures canvas")
    expect(page).to have_selector("#question-routing-guardrails-failures canvas")
    expect(page).to have_selector("#topics canvas")
    expect(page).to have_selector("#answer-completeness canvas")
  end

  def and_i_can_see_its_for_last_24_hours
    expect(page).to have_selector(".gem-c-secondary-navigation__list-item--current",
                                  text: "Last 24 hours")
  end

  def when_i_navigate_to_view_last_7_days
    click_link "Last 7 days"
  end

  def and_i_can_see_its_for_last_7_days
    expect(page).to have_selector(".gem-c-secondary-navigation__list-item--current",
                                  text: "Last 7 days")
  end
end
