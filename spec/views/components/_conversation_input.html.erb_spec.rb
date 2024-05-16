RSpec.describe "components/_conversation_input.html.erb" do
  it "renders the conversation input component correctly" do
    render("components/conversation_input", {
      id: "id",
      name: "name",
      value: "Value",
    })

    expect(rendered).to have_selector(".app-c-conversation-input") do |rendered_input|
      expect(rendered_input)
        .to have_selector(".app-c-conversation-input__label.govuk-visually-hidden", text: /Enter your question/)
        .and have_selector(".app-c-conversation-input__input[id=id][name=name][value=Value]")
        .and have_selector(".gem-c-hint", text: /Please limit your question/)
    end
  end

  it "renders error messages when there is a problem" do
    render("components/conversation_input", {
      id: "id",
      name: "name",
      value: "Value",
      error_items: [
        {
          text: "Error 1",
        },
      ],
    })

    expect(rendered)
      .to have_selector(".app-c-conversation-input .gem-c-error-message", text: "Error: Error 1")
  end
end
