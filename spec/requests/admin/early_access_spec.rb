RSpec.describe "Admin::EarlyAccessController" do
  describe "GET :index" do
    it "renders the page successfully" do
      get admin_early_access_users_path

      expect(response).to have_http_status(:ok)
    end

    it "renders an empty state" do
      get admin_early_access_users_path

      expect(response.body).to have_content("No users found")
    end

    it "renders the table headers correctly" do
      create(:early_access_user)

      get admin_early_access_users_path

      expect(response.body)
        .to have_link("Email", href: admin_early_access_users_path(sort: "email"))
        .and have_link("Last login", href: admin_early_access_users_path(sort: "last_login_at"))
        .and have_selector(".govuk-table__header", text: "Questions asked")
        .and have_selector(".govuk-table__header", text: "Access revoked?")
    end

    context "when there are multiple pages of users" do
      before do
        create_list(:early_access_user, 26)
      end

      it "paginates correctly on page 1" do
        get admin_early_access_users_path

        expect(response.body)
          .to have_link("Next page", href: admin_early_access_users_path(page: 2))
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
        expect(response.body).not_to have_content("Previous page")
      end

      it "paginates correctly on page 2" do
        get admin_early_access_users_path(page: 2)

        expect(response.body)
          .to have_link("Previous page", href: admin_early_access_users_path)
          .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        expect(response.body).not_to have_content("Next page")
      end
    end

    context "when filter parameters are provided" do
      it "renders the page successfully" do
        get admin_early_access_users_path(source: "instant_signup")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when sorting" do
      it "orders the users correctly when the sort param is 'last_login_at'" do
        create(:early_access_user, email: "a@example.com", last_login_at: 1.hour.ago)
        create(:early_access_user, email: "b@example.com", last_login_at: 1.day.ago)
        create(:early_access_user, email: "c@example.com", last_login_at: 1.minute.ago)

        get admin_early_access_users_path(sort: "last_login_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/b@example\.com.*a@example\.com.*c@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'last_login_at'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "last_login_at")

        expect(response.body)
          .to have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Last login")
          .and have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_no_selector(".govuk-table__header--active", text: "Email")
      end

      it "orders the users correctly when the sort param is '-last_login_at'" do
        create(:early_access_user, email: "a@example.com", last_login_at: 1.hour.ago)
        create(:early_access_user, email: "b@example.com", last_login_at: 1.day.ago)
        create(:early_access_user, email: "c@example.com", last_login_at: 1.minute.ago)

        get admin_early_access_users_path(sort: "-last_login_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*a@example\.com.*b@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-last_login_at'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "-last_login_at")

        expect(response.body)
          .to have_link("Last login", href: admin_early_access_users_path(sort: "last_login_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Last login")
          .and have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_no_selector(".govuk-table__header--active", text: "Email")
      end

      it "orders the users correctly when the sort param is 'email'" do
        create(:early_access_user, email: "a@example.com")
        create(:early_access_user, email: "c@example.com")
        create(:early_access_user, email: "b@example.com")

        get admin_early_access_users_path(sort: "email")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/a@example\.com.*b@example\.com.*c@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'email'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "email")

        expect(response.body)
          .to have_link("Email", href: admin_early_access_users_path(sort: "-email"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Email")
          .and have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Last login")
      end

      it "orders the users correctly when the sort param is '-email'" do
        create(:early_access_user, email: "a@example.com")
        create(:early_access_user, email: "c@example.com")
        create(:early_access_user, email: "b@example.com")

        get admin_early_access_users_path(sort: "-email")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*b@example\.com.*a@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-email'" do
        create(:early_access_user)

        get admin_early_access_users_path(sort: "-email")

        expect(response.body)
          .to have_link("Email", href: admin_early_access_users_path(sort: "email"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Email")
          .and have_link("Last login", href: admin_early_access_users_path(sort: "-last_login_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Last login")
      end
    end
  end
end
