RSpec.describe "components/_landing.html.erb" do
  it "renders the landing component correctly" do
    render("components/landing", {
      title_text: "Title text",
      lead_paragraph_text: "Lead paragraph text",
    })

    expect(rendered)
      .to have_selector(".app-c-landing")
      .and have_selector(".app-c-landing__svg-container")
      .and have_selector(".app-c-landing__title", text: "Title text")
      .and have_selector(".app-c-landing__lead-paragraph", text: "Lead paragraph text")
  end

  it "renders additional info text when provided and generates an 'info-text' id" do
    render("components/landing", {
      title_text: "Title text",
      lead_paragraph_text: "Lead paragraph text",
      info_text: "Info text",
    })

    expect(rendered)
      .to have_selector("#info-text")
  end

  it "does not render the landing component if not provided with title text and lead paragraph text" do
    render("components/landing")

    expect(rendered)
      .not_to have_selector(".app-c-landing")
  end
end
