RSpec.describe "components/_chat_introduction_title.html.erb" do
  it "renders the chat introduction title component correctly" do
    render("components/chat_introduction_title", {
      title: "Try GOV.UK Chat",
    })

    expect(rendered)
      .to have_selector(".app-c-chat-introduction-title")
      .and have_selector(".app-c-chat-introduction-title__title", text: "Try GOV.UK Chat")
  end

  context "when with_logo is true" do
    it "renders the chat logo" do
      render("components/chat_introduction_title", {
        title: "Title",
        with_logo: true,
      })

      expect(rendered)
        .to have_selector(".app-c-chat-introduction-title__svg-container")
        .and have_selector(".app-c-chat-introduction-title__svg")
    end
  end

  context "when standfirst paragraphs are provided" do
    it "renders the paragraphs accordingly" do
      render("components/chat_introduction_title", {
        title: "Title",
        standfirst_paragraphs: [
          "This is a standfirst paragraph",
        ],
      })

      expect(rendered)
        .to have_selector(".app-c-chat-introduction-title__lead-paragraph.govuk-body", text: "This is a standfirst paragraph")
    end
  end
end
