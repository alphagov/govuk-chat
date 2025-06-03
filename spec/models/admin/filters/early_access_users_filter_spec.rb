RSpec.describe Admin::Filters::EarlyAccessUsersFilter do
  describe "#results" do
    describe "ordering" do
      let!(:logged_in_1_min_ago) { create(:early_access_user, email: "alice@example.com", last_login_at: 1.minute.ago) }
      let!(:never_logged_in) { create(:early_access_user, email: "betty@example.com", last_login_at: nil) }
      let!(:logged_in_1_hour_ago) { create(:early_access_user, email: "clive@example.com", last_login_at: 1.hour.ago) }

      it "orders the results by the most recently logged in" do
        results = described_class.new.results
        expect(results).to eq([logged_in_1_min_ago, logged_in_1_hour_ago, never_logged_in])
      end

      it "orders the results by the most recently logged in when the sort param is '-last_login_at'" do
        results = described_class.new(sort: "-last_login_at").results
        expect(results).to eq([logged_in_1_min_ago, logged_in_1_hour_ago, never_logged_in])
      end

      it "orders the results by the least recently logged in when the sort param is 'last_login_at'" do
        results = described_class.new(sort: "last_login_at").results
        expect(results).to eq([never_logged_in, logged_in_1_hour_ago, logged_in_1_min_ago])
      end

      it "orders the results by email when the sort param is 'email'" do
        results = described_class.new(sort: "email").results
        expect(results).to eq([logged_in_1_min_ago, never_logged_in, logged_in_1_hour_ago])
      end

      it "orders the results by reverse email when the sort param is '-email'" do
        results = described_class.new(sort: "-email").results
        expect(results).to eq([logged_in_1_hour_ago, never_logged_in, logged_in_1_min_ago])
      end

      it "orders the results by questions_count when the sort param is 'questions_count'" do
        user = create :early_access_user, questions_count: 2
        results = described_class.new(sort: "questions_count").results
        expect(results.last).to eq(user)
      end

      it "orders the results by reverse questions_count when the sort param is '-questions_count'" do
        user = create :early_access_user, questions_count: 2
        results = described_class.new(sort: "-questions_count").results
        expect(results.first).to eq(user)
      end
    end

    it "paginates the results" do
      create_list(:early_access_user, 26)

      results = described_class.new(page: 1).results
      expect(results.count).to eq(25)

      results = described_class.new(page: 2).results
      expect(results.count).to eq(1)
    end
  end

  describe "filtering" do
    it "filters by email" do
      alice = create(:early_access_user, email: "alice@example.com")
      bob = create(:early_access_user, email: "bob@example.com")
      lisa = create(:early_access_user, email: "lisa@example.com")

      filter = described_class.new(email: "alice")
      expect(filter.results).to eq([alice])

      filter = described_class.new(email: "bob")
      expect(filter.results).to eq([bob])

      filter = described_class.new(email: "li")
      expect(filter.results).to contain_exactly(alice, lisa)
    end

    it "filters by source" do
      instant_signup_user = create(:early_access_user, source: :instant_signup)
      admin_added_user = create(:early_access_user, source: :admin_added)

      filter = described_class.new(source: :instant_signup)
      expect(filter.results).to eq([instant_signup_user])

      filter = described_class.new(source: :admin_added)
      expect(filter.results).to eq([admin_added_user])
    end

    it "filters by previous sign up denied status" do
      user_previously_denied_sign_up = create(:early_access_user, previous_sign_up_denied: true)
      user_not_previously_denied_sign_up = create(:early_access_user, previous_sign_up_denied: false)

      filter = described_class.new(previous_sign_up_denied: "true")
      expect(filter.results).to eq([user_previously_denied_sign_up])

      filter = described_class.new(previous_sign_up_denied: "false")
      expect(filter.results).to eq([user_not_previously_denied_sign_up])
    end
  end

  it_behaves_like "a paginatable filter", :early_access_user

  it_behaves_like "a sortable filter", "last_login_at"
end
