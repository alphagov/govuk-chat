RSpec.describe "components/_conversation_form.html.erb" do
  it "renders the conversation form component correctly" do
    render("components/conversation_form", {
      url: "/conversation",
      input_id: "id",
      name: "name",
      value: "Value",
    })

    expect(rendered).to have_selector('.app-c-conversation-form[action="/conversation"]') do |rendered_form|
      expect(rendered_form)
        .to have_selector(".app-c-conversation-form__label.govuk-visually-hidden", text: /Enter your question/)
        .and have_selector(".app-c-conversation-form__input[id=id][name=name][value=Value]")
        .and have_selector(".gem-c-hint", text: /Please limit your question/)
        .and have_selector(".app-c-blue-button")
    end
  end

  it "renders error messages when there is a problem" do
    render("components/conversation_form", {
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
      .to have_selector(".app-c-conversation-form .gem-c-error-message", text: "Error: Error 1")
      .and have_selector(".app-c-conversation-form__input[aria-describedby~=id-error]")
  end
end
