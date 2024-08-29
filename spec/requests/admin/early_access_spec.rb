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

    it "renders the table body correctly" do
      user = create(:early_access_user, email: "alice@example.com")

      get admin_early_access_users_path

      expect(response.body)
        .to have_link("alice@example.com", href: admin_early_access_user_path(user))
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

  describe "GET :show" do
    it "renders the user details" do
      user = create(
        :early_access_user,
        email: "alice@example.com",
        last_login_at: Time.zone.parse("2024-1-1 12:13:14"),
        user_description: :business_owner_or_self_employed,
        reason_for_visit: :find_specific_answer,
        revoked_at: nil,
        question_limit: 0,
      )

      get admin_early_access_user_path(user)

      expect(response.body)
        .to have_content("User details")
        .and have_content("alice@example.com")
        .and have_content("12:13pm on 1 January 2024")
        .and have_content("business_owner_or_self_employed")
        .and have_content("find_specific_answer")
        .and have_content("Unlimited")
    end

    it "renders the edit user link" do
      user = create(:early_access_user)

      get admin_early_access_user_path(user)

      expect(response.body).to have_link("Edit user", href: edit_admin_early_access_user_path(user))
    end

    it "renders the revoked details" do
      user = create(
        :early_access_user,
        revoked_at: Time.zone.parse("2024-1-2 09:10:11"),
        revoked_reason: "Asking too many questions",
      )

      get admin_early_access_user_path(user)

      expect(response.body)
        .to have_content("9:10am on 2 January 2024")
        .and have_content("Asking too many questions")
    end
  end

  describe "GET :new" do
    it "renders the form" do
      get new_admin_early_access_user_path
      expect(response).to have_http_status(:ok)

      expect(response.body).to have_content("New early access user")
    end
  end

  describe "POST :create" do
    it "creates a new user and redirects" do
      post admin_early_access_users_path, params: { create_early_access_user_form: { email: "new.user@example.com" } }

      expect(EarlyAccessUser.last).to have_attributes(
        email: "new.user@example.com",
        source: "admin_added",
      )
      expect(response).to redirect_to(admin_early_access_user_path(EarlyAccessUser.last))
    end

    it "renders the form with errors" do
      post admin_early_access_users_path, params: { create_early_access_user_form: { email: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_content("Enter an email address")
    end
  end

  describe "GET :edit" do
    it "renders the form" do
      get edit_admin_early_access_user_path(create(:early_access_user))

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_content("Edit early access user")
        .and have_content("Question limit")
    end
  end

  describe "PATCH :update" do
    it "updates the user and redirects" do
      user = create(:early_access_user, question_limit: 2)

      patch admin_early_access_user_path(user),
            params: {
              update_early_access_user_form: {
                question_limit: 3,
              },
            }

      expect(user.reload).to have_attributes(
        question_limit: 3,
      )

      expect(response).to redirect_to(admin_early_access_user_path(user))
    end

    it "renders the form with errors" do
      user = create(:early_access_user)

      patch admin_early_access_user_path(user),
            params: {
              update_early_access_user_form: {
                question_limit: "invalid",
              },
            }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_content("Question limit must be a number or blank")
    end
  end
end
