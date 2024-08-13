RSpec.describe Admin::Form::EarlyAccessUsersFilter do
  describe "#users" do
    describe "ordering" do
      let!(:logged_in_1_min_ago) { create(:early_access_user, email: "alice@example.com", last_login_at: 1.minute.ago) }
      let!(:never_logged_in) { create(:early_access_user, email: "betty@example.com", last_login_at: nil) }
      let!(:logged_in_1_hour_ago) { create(:early_access_user, email: "clive@example.com", last_login_at: 1.hour.ago) }

      it "orders the users by the most recently logged in" do
        users = described_class.new.users
        expect(users).to eq([logged_in_1_min_ago, logged_in_1_hour_ago, never_logged_in])
      end

      it "orders the users by the most recently logged in when the sort param is '-last_login_at'" do
        users = described_class.new(sort: "-last_login_at").users
        expect(users).to eq([logged_in_1_min_ago, logged_in_1_hour_ago, never_logged_in])
      end

      it "orders the users by the least recently logged in when the sort param is 'last_login_at'" do
        users = described_class.new(sort: "last_login_at").users
        expect(users).to eq([never_logged_in, logged_in_1_hour_ago, logged_in_1_min_ago])
      end

      it "orders the users by email when the sort param is 'email'" do
        users = described_class.new(sort: "email").users
        expect(users).to eq([logged_in_1_min_ago, never_logged_in, logged_in_1_hour_ago])
      end

      it "orders the users by reverse email when the sort param is '-email'" do
        users = described_class.new(sort: "-email").users
        expect(users).to eq([logged_in_1_hour_ago, never_logged_in, logged_in_1_min_ago])
      end
    end

    it "paginates the users" do
      create_list(:early_access_user, 26)

      users = described_class.new(page: 1).users
      expect(users.count).to eq(25)

      users = described_class.new(page: 2).users
      expect(users.count).to eq(1)
    end
  end

  describe "#previous_page_params" do
    it "returns any empty hash if there is no previous page to link to" do
      filter = described_class.new
      expect(filter.previous_page_params).to eq({})
    end

    it "constructs the previous pages url based on the path passed in when a previous page is present" do
      create_list(:early_access_user, 51)
      filter = described_class.new(page: 3)
      expect(filter.previous_page_params).to eq({ page: 2 })
    end

    it "removes the page param from the url correctly when it links to the first page of users" do
      create_list(:early_access_user, 26)
      filter = described_class.new(page: 2)
      expect(filter.previous_page_params).to eq({})
    end
  end

  describe "#next_page_params" do
    it "returns any empty hash if there is no next page to link to" do
      filter = described_class.new
      expect(filter.next_page_params).to eq({})
    end

    it "constructs the next page based on the path passed in when a next page is present" do
      create_list(:early_access_user, 26)
      filter = described_class.new(page: 1)
      expect(filter.next_page_params).to eq({ page: 2 })
    end
  end

  describe "#sort_direction" do
    it "returns nil when sort does not match the field passed in" do
      filter = described_class.new(sort: "email")
      expect(filter.sort_direction("last_login_at")).to be_nil
    end

    it "returns 'ascending' when sort equals the field passed in" do
      filter = described_class.new(sort: "email")
      expect(filter.sort_direction("email")).to eq("ascending")
    end

    it "returns 'descending' when sort prefixed with '-' equals the field passed in" do
      filter = described_class.new(sort: "-email")
      expect(filter.sort_direction("email")).to eq("descending")
    end
  end

  describe "#toggleable_sort_params" do
    it "sets the page param to nil" do
      filter = described_class.new(sort: "-email", page: 2)
      expect(filter.toggleable_sort_params("-email")).to eq({ sort: "email", page: nil })
    end

    context "when the sort attribute does not match the default_field_sort" do
      it "sets the sort_param to the default_field_sort" do
        filter = described_class.new(sort: "email")
        expect(filter.toggleable_sort_params("-email")).to eq({ sort: "-email", page: nil })
      end
    end

    context "when the sort attribute matches the default_field_sort" do
      it "sets the sort_param to 'ascending' if the sort attribute is 'descending'" do
        filter = described_class.new(sort: "-email")
        expect(filter.toggleable_sort_params("-email")).to eq({ sort: "email", page: nil })
      end

      it "sets the sort_param to 'descending' if the sort attribute is 'ascending'" do
        filter = described_class.new(sort: "email")
        expect(filter.toggleable_sort_params("email")).to eq({ sort: "-email", page: nil })
      end
    end
  end
end
