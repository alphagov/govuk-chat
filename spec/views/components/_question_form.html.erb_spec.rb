RSpec.describe "components/_question_form.html.erb" do
  it "renders the conversation form component correctly" do
    render("components/question_form", {
      url: "/conversation",
      input_id: "id",
      name: "name",
      value: "Value",
    })

    expect(rendered).to have_selector('.app-c-question-form__form[action="/conversation"]') do |rendered_form|
      expect(rendered_form)
        .to have_selector(".app-c-question-form__label.govuk-visually-hidden", text: /Message/)
        .and have_selector(".app-c-question-form__input[placeholder=Message]")
        .and have_selector(".app-c-question-form__input[id=id][name=name][value=Value]")
        .and have_selector(".gem-c-hint", text: /Please limit your question/)
        .and have_selector(".govuk-error-message[hidden]", visible: :hidden)
        .and have_selector(".app-c-blue-button")
      expect(rendered).not_to have_selector(".app-c-question-form__error-message")
    end

    expect(rendered).to have_link("Share your feedback (opens in a new tab)")
  end

  it "includes a user id if one is provided" do
    user_id = SecureRandom.uuid
    render("components/question_form", {
      url: "/conversation",
      name: "name",
      user_id:,
    })

    expect(rendered)
      .to have_link("Share your feedback (opens in a new tab)", href: /\?user=#{user_id}/)
  end

  it "includes data attributes of server side validation parameters" do
    render("components/question_form", {
      url: "/conversation",
      input_id: "id",
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
      input_id: "id",
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
      .and have_selector(".app-c-question-form__input[aria-describedby~=id-error]")
  end

  it "renders the remaining questions hint" do
    render("components/question_form", {
      url: "/conversation",
      name: "name",
      remaining_questions_copy: "6 messages left",
    })

    expect(rendered)
      .to have_selector(".js-remaining-questions-hint", text: "6 messages left")
      .and have_selector(".app-c-question-form__input[aria-describedby*=js-remaining-questions-hint]")
  end
end
