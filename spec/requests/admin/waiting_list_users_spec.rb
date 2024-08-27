RSpec.describe "Admin::WaitingListUsersController" do
  describe "GET :index" do
    it "renders the page successfully" do
      get admin_waiting_list_users_path

      expect(response).to have_http_status(:ok)
    end

    it "renders a link to the new user form" do
      get admin_waiting_list_users_path

      expect(response.body).to have_link("Add user", href: new_admin_waiting_list_user_path)
    end

    it "renders an empty state" do
      get admin_waiting_list_users_path

      expect(response.body).to have_content("No users found")
    end

    it "renders the table headers correctly" do
      create(:waiting_list_user)

      get admin_waiting_list_users_path

      expect(response.body)
        .to have_link("Email", href: admin_waiting_list_users_path(sort: "email"))
        .and have_link("Created", href: admin_waiting_list_users_path(sort: "created_at"))
    end

    it "renders the table body correctly" do
      user = create(:waiting_list_user, email: "alice@example.com")

      get admin_waiting_list_users_path

      expect(response.body)
        .to have_link("alice@example.com", href: admin_waiting_list_user_path(user))
        .and have_selector(".govuk-table__cell", text: user.created_at.to_fs(:time_and_date))
    end

    context "when there are multiple pages of users" do
      before do
        create_list(:waiting_list_user, 26)
      end

      it "paginates correctly on page 1" do
        get admin_waiting_list_users_path

        expect(response.body)
          .to have_link("Next page", href: admin_waiting_list_users_path(page: 2))
          .and have_selector(".govuk-pagination__link-label", text: "2 of 2")
        expect(response.body).not_to have_content("Previous page")
      end

      it "paginates correctly on page 2" do
        get admin_waiting_list_users_path(page: 2)

        expect(response.body)
          .to have_link("Previous page", href: admin_waiting_list_users_path)
          .and have_selector(".govuk-pagination__link-label", text: "1 of 2")
        expect(response.body).not_to have_content("Next page")
      end
    end

    context "when filter parameters are provided" do
      it "renders the page successfully" do
        get admin_waiting_list_users_path(email: "user@example.com")
        expect(response).to have_http_status(:ok)
      end

      it "filters the users correctly when the filter param is 'email'" do
        create(:waiting_list_user, email: "adam@example.com")
        create(:waiting_list_user, email: "betty@example.com")
        create(:waiting_list_user, email: "jetty@example.com")

        get admin_waiting_list_users_path(email: "etty")

        expect(response.body)
          .to have_content("betty@example.com")
          .and have_content("jetty@example.com")
          .and have_no_content("adam@example.com")
      end
    end

    context "when sorting" do
      it "orders the users correctly when the sort param is 'created_at'" do
        create(:waiting_list_user, email: "a@example.com", created_at: 1.hour.ago)
        create(:waiting_list_user, email: "b@example.com", created_at: 1.day.ago)
        create(:waiting_list_user, email: "c@example.com", created_at: 1.minute.ago)

        get admin_waiting_list_users_path(sort: "created_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/b@example\.com.*a@example\.com.*c@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'created_at'" do
        create(:waiting_list_user)

        get admin_waiting_list_users_path(sort: "created_at")

        expect(response.body)
          .to have_link("Created", href: admin_waiting_list_users_path(sort: "-created_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Created")
          .and have_link("Email", href: admin_waiting_list_users_path(sort: "email"))
          .and have_no_selector(".govuk-table__header--active", text: "Email")
      end

      it "orders the users correctly when the sort param is '-created_at'" do
        create(:waiting_list_user, email: "a@example.com", created_at: 1.hour.ago)
        create(:waiting_list_user, email: "b@example.com", created_at: 1.day.ago)
        create(:waiting_list_user, email: "c@example.com", created_at: 1.minute.ago)

        get admin_waiting_list_users_path(sort: "-created_at")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*a@example\.com.*b@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-created_at'" do
        create(:waiting_list_user)

        get admin_waiting_list_users_path(sort: "-created_at")

        expect(response.body)
          .to have_link("Created", href: admin_waiting_list_users_path(sort: "created_at"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Created")
          .and have_link("Email", href: admin_waiting_list_users_path(sort: "email"))
          .and have_no_selector(".govuk-table__header--active", text: "Email")
      end

      it "orders the users correctly when the sort param is 'email'" do
        create(:waiting_list_user, email: "a@example.com")
        create(:waiting_list_user, email: "c@example.com")
        create(:waiting_list_user, email: "b@example.com")

        get admin_waiting_list_users_path(sort: "email")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/a@example\.com.*b@example\.com.*c@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is 'email'" do
        create(:waiting_list_user)

        get admin_waiting_list_users_path(sort: "email")

        expect(response.body)
          .to have_link("Email", href: admin_waiting_list_users_path(sort: "-email"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--ascending", text: "Email")
          .and have_link("Created", href: admin_waiting_list_users_path(sort: "-created_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Created")
      end

      it "orders the users correctly when the sort param is '-email'" do
        create(:waiting_list_user, email: "a@example.com")
        create(:waiting_list_user, email: "c@example.com")
        create(:waiting_list_user, email: "b@example.com")

        get admin_waiting_list_users_path(sort: "-email")

        expect(response.body).to have_selector(".govuk-table") do |match|
          expect(match).to have_content(/c@example\.com.*b@example\.com.*a@example\.com/m)
        end
      end

      it "renders the sortable table headers correctly when the sort param is '-email'" do
        create(:waiting_list_user)

        get admin_waiting_list_users_path(sort: "-email")

        expect(response.body)
          .to have_link("Email", href: admin_waiting_list_users_path(sort: "email"))
          .and have_selector(".govuk-table__header--active .app-table__sort-link--descending", text: "Email")
          .and have_link("Created", href: admin_waiting_list_users_path(sort: "-created_at"))
          .and have_no_selector(".govuk-table__header--active", text: "Created")
      end
    end
  end

  describe "GET :show" do
    it "renders the user details" do
      user = create(
        :waiting_list_user,
        email: "alice@example.com",
        user_description: :business_owner_or_self_employed,
        reason_for_visit: :find_specific_answer,
      )

      get admin_waiting_list_user_path(user)

      expect(response.body)
        .to have_content("User details")
        .and have_content("alice@example.com")
        .and have_content(user.created_at.to_fs(:time_and_date))
        .and have_content("business_owner_or_self_employed")
        .and have_content("find_specific_answer")
    end
  end

  describe "GET :new" do
    it "renders the form" do
      get new_admin_waiting_list_user_path
      expect(response).to have_http_status(:ok)

      expect(response.body).to have_content("New waiting list user")
    end
  end

  describe "POST :create" do
    it "creates a new user and redirects" do
      post admin_waiting_list_users_path,
           params: {
             create_waiting_list_user_form: {
               email: "new.user@example.com",
               user_description: "business_administrator",
               reason_for_visit: "research_topic",
             },
           }

      expect(WaitingListUser.last).to have_attributes(
        email: "new.user@example.com",
        user_description: "business_administrator",
        reason_for_visit: "research_topic",
        source: "admin_added",
      )
      expect(response).to redirect_to(admin_waiting_list_user_path(WaitingListUser.last))
    end

    it "renders the form with errors" do
      post admin_waiting_list_users_path, params: { create_waiting_list_user_form: { email: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_content("Enter an email address")
    end
  end
end
