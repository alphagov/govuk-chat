RSpec.describe "components/_answer_feedback_form.html.erb" do
  it "renders the form based on the url passed in" do
    render("components/answer_feedback_form", {
      url: "/answer-feedback",
    })

    expect(rendered)
      .to have_selector("form[action='/answer-feedback']")
      .and have_selector(".app-c-answer-feedback-form .app-c-answer-feedback-form__button", text: "Useful")
      .and have_selector(".app-c-answer-feedback-form .app-c-answer-feedback-form__button", text: "not useful")
  end

  it "renders a hidden div with a thank you message and hide button" do
    render("components/answer_feedback_form", {
      url: "/answer-feedback",
    })

    expect(rendered)
      .to have_selector(
        ".app-c-answer-feedback-form__feedback-submitted",
        visible: :hidden,
        text: /Thanks for your feedback./,
      )
      .and have_button(
        "Hide this message",
        visible: :hidden,
      )
  end
end
