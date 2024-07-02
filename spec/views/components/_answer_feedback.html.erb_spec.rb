RSpec.describe "components/_answer_feedback.html.erb" do
  it "renders the form based on the url passed in" do
    render("components/answer_feedback", {
      url: "/answer-feedback",
    })

    expect(rendered)
      .to have_selector(".app-c-answer-feedback__form[action='/answer-feedback']")
      .and have_selector(".app-c-answer-feedback__fieldset") do |fieldset|
        expect(fieldset)
          .to have_selector(".govuk-fieldset__legend", text: "How was this answer?")
          .and have_button("This answer was Useful")
          .and have_button("This answer was not useful")
      end
  end

  it "renders a hidden div with a thank you message and hide button" do
    render("components/answer_feedback", {
      url: "/answer-feedback",
    })

    expect(rendered)
      .to have_selector(
        ".app-c-answer-feedback__feedback-submitted",
        visible: :hidden,
        text: /Thanks for your feedback./,
      )
      .and have_button(
        "Hide this message",
        visible: :hidden,
      )
  end
end
