RSpec.describe "components/_question_form.html.erb" do
  it "renders the conversation form component correctly" do
    render("components/question_form", {
      url: "/conversation",
      textarea_id: "id",
      name: "name",
      value: "Value",
    })

    expect(rendered).to have_selector('.app-c-question-form__form[action="/conversation"]') do |rendered_form|
      expect(rendered_form)
        .to have_selector(".app-c-question-form__label.govuk-visually-hidden", text: /Message/)
        .and have_selector(".app-c-question-form__textarea[placeholder=Message]")
        .and have_selector(".app-c-question-form__textarea[id=id][name=name]", text: "Value")
        .and have_selector(".gem-c-hint", text: /Please limit your question/)
        .and have_selector(".govuk-error-message[hidden]", visible: :hidden)
        .and have_selector(".app-c-blue-button")
      expect(rendered).not_to have_selector(".app-c-question-form__error-message")
    end
  end

  it "includes data attributes of server side validation parameters" do
    render("components/question_form", {
      url: "/conversation",
      textarea_id: "id",
      name: "name",
      value: "Value",
    })

    presence_error_message = Form::CreateQuestion::USER_QUESTION_PRESENCE_ERROR_MESSAGE.gsub("\'", "\\\\'")

    expect(rendered)
      .to have_selector(".app-c-question-form[data-presence-error-message='#{presence_error_message}']")
  end

  it "renders error messages when there is a problem" do
    render("components/question_form", {
      url: "/conversation",
      textarea_id: "id",
      name: "name",
      error_items: [
        {
          text: "Error 1",
        },
      ],
    })

    expect(rendered)
      .to have_selector(".app-c-question-form .govuk-error-message:not([hidden])", text: /Error:\s+Error 1/)
      .and have_selector(".app-c-question-form__error-message", text: /Error 1/)
      .and have_selector(".app-c-question-form__textarea[aria-describedby~=id-error]")
  end
end
