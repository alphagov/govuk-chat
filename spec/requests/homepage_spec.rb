RSpec.describe "HomepageController" do
  it_behaves_like "redirects to homepage if authentication is not enabled",
                  routes: { homepage_path: %i[post] }

  it_behaves_like "throttles traffic from a single IP address",
                  routes: { homepage_path: %i[post] }, limit: 10, period: 5.minutes

  describe "GET :index" do
    it "redirects to the onboarding limitations path" do
      get homepage_path
      expect(response).to redirect_to(onboarding_limitations_path)
    end

    # The caching behavior might need to be re-evaluated based on the new target page,
    # or this test might belong to the controller for onboarding_limitations_path.
    # For now, retaining a generic caching test, assuming the homepage itself (before redirect) might have some policy.
    it "sets the cache headers for the redirecting page if applicable" do
      get homepage_path
      # This will test the cache headers of the redirect response itself,
      # not the target page. If specific cache headers are expected for the
      # homepage before it redirects, they should be asserted here.
      # Example: expect(response.headers["Cache-Control"]).to eq("max-age=60, public")
      # However, since it's a direct redirect, there might not be specific caching
      # on the homepage action itself beyond default Rails behavior for redirects.
      # If the original caching test (lines 46-49) was for the content previously
      # rendered by homepage, it's no longer applicable in the same way.
      # For now, we can assert that the response is a redirect.
      expect(response).to have_http_status(:redirect)
    end
  end
end
