RSpec.describe "components/_answer.html.erb" do
  it "renders the answer component correctly" do
    render("components/answer", {
      id: "answer-1",
      message: "message 1",
    })

    assert_select "div.app-c-answer#answer-1" do
      assert_select ".app-c-answer__identifier .app-c-answer__identifier-icon"
      assert_select ".app-c-answer__identifier .app-c-answer__identifier-heading", text: "GOV.UK Chat (experimental)"
      assert_select ".app-c-answer__message", text: "message 1"
      assert_select ".govuk-details", count: 0
    end
  end

  it "applies data attributes when provided" do
    render("components/answer", {
      id: "answer-2",
      message: "message 2",
      data_attributes: {
        track_category: "track-category",
        track_action: "track-action",
        track_label: "track-label",
      },
    })

    assert_select '.app-c-answer[data-track-category="track-category"]'
    assert_select '.app-c-answer[data-track-action="track-action"]'
    assert_select '.app-c-answer[data-track-label="track-label"]'
  end

  it "renders sources as links in a details component when provided" do
    render("components/answer", {
      id: "answer-3",
      message: "message 3",
      sources: [
        "http://example.com",
        "http://example.gov.uk",
      ],
    })

    assert_select ".govuk-details a[href='http://example.com']", text: "http://example.com"
    assert_select ".govuk-details a[href='http://example.gov.uk']", text: "http://example.gov.uk"
  end
end
