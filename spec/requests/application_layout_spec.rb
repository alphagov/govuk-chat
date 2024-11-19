RSpec.describe "Application layout" do
  it "renders the navbar link to the homepage" do
    get about_path

    expect(response.body)
      .to have_selector("a.app-c-header__link[href='#{homepage_path}']")
  end

  context "when an early access user is signed in" do
    include_context "when signed in"

    context "and public access is disabled" do
      before { Settings.instance.update!(public_access_enabled: false) }

      it "renders the navbar link to the homepage" do
        get about_path

        expect(response.body)
          .to have_selector("a.app-c-header__link[href='#{homepage_path}']")
      end
    end
  end

  context "when an error occurs when checking for an access user" do
    let(:error) { RuntimeError.new("Random error") }

    before do
      # We need to ensure somewhere in the code to check for user an error occurs.
      # This seemed the easiest spot to mock
      allow(Passwordless::Session).to receive(:find_by).and_raise(error)
    end

    it "renders the navbar link as if the user is logged out" do
      # we use an error route as these won't check for signed in outside of the view
      get "/404"

      expect(response.body)
        .to have_selector("a.app-c-header__link[href='#{homepage_path}']")
    end

    it "notifies Sentry about the error" do
      expect(GovukError).to receive(:notify).with(error)

      get "/404"
    end
  end
end
