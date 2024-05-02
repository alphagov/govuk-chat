RSpec.describe "components/_code_snippet.html.erb" do
  it "applies data attributes when provided" do
    render("components/code_snippet", {
      content: "This should be in the the pre.",
    })

    expect(rendered)
      .to have_selector(
        ".app-c-code-snippet .app-c-code-snippet__pre",
        text: "This should be in the the pre.",
      )
  end
end
