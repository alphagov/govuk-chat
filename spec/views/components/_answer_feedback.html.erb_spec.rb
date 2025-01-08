RSpec.describe "components/_answer_feedback.html.erb" do
  it "renders the form based on the url passed in" do
    render("components/answer_feedback", {
      url: "/answer-feedback",
      question_message: "How do I apply for teacher training?",
    })

    expect(rendered)
      .to have_selector(".app-c-answer-feedback__form[action='/answer-feedback']")
      .and have_selector(".app-c-answer-feedback__fieldset") do |fieldset|
        expect(fieldset)
          .to have_selector(".govuk-fieldset__legend", text: "How was this answer?")
          .and have_button("The answer to \"How do I apply for teacher training?\" was Useful")
          .and have_button("The answer was not useful")
      end
  end

  it "renders a hidden div with a thank you message" do
    user_id = SecureRandom.uuid
    render("components/answer_feedback", {
      url: "/answer-feedback",
      question_message: "How do I apply for teacher training?",
      user_id:,
    })

    expect(rendered)
      .to have_selector(
        ".app-c-answer-feedback__feedback-submitted",
        visible: :hidden,
        text: /Thanks for your feedback./,
      )
  end
end
