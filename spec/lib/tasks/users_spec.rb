RSpec.describe "users rake tasks" do
  describe "users:promote_waiting_list" do
    let(:task_name) { "users:promote_waiting_list" }
    let!(:waiting_list_users) { create_list :waiting_list_user, 3 }
    let(:early_access_users) { EarlyAccessUser.all }
    let(:settings) { Settings.instance }

    before do
      Rake::Task[task_name].reenable
    end

    shared_examples "promotes waiting list users" do |expected_promotions|
      let(:max_places) do
        [
          settings.waiting_list_promotions_per_run,
          settings.delayed_access_places,
        ].min
      end

      before do
        allow(WaitingListUser)
          .to receive(:users_to_promote)
          .with(max_places)
          .and_return(waiting_list_users.first(max_places))
      end

      it "randomises the users selected for promotion" do
        expect { Rake::Task[task_name].invoke }.to output.to_stdout
        expect(WaitingListUser).to have_received(:users_to_promote).with(max_places)
      end

      it "add EarlyAccessUsers and deletes WaitingListUsers" do
        expect { Rake::Task[task_name].invoke }.to change(EarlyAccessUser, :count).by(expected_promotions)
          .and change(WaitingListUser, :count).by(-expected_promotions)
          .and output.to_stdout
      end

      it "copies the attributes across correctly" do
        expect { Rake::Task[task_name].invoke }.to output.to_stdout
        expected = waiting_list_users.take(expected_promotions).map { |u| [u.email, u.user_description, u.reason_for_visit, "delayed_signup"] }
        actual = early_access_users.last(expected_promotions).pluck(:email, :user_description, :reason_for_visit, :source)
        expect(actual).to eq(expected)
      end

      it "locks the settings and decrements the available places" do
        allow(Settings).to receive(:instance).and_return(settings)
        expect(settings).to receive(:with_lock).and_call_original
        expect { Rake::Task[task_name].invoke }.to change(settings, :delayed_access_places).by(-expected_promotions)
          .and output.to_stdout
      end

      it "sends an email to each user" do
        expect { Rake::Task[task_name].invoke }.to change(EarlyAccessAuthMailer.deliveries, :count).by(expected_promotions)
          .and output.to_stdout
      end
    end

    context "when number of waiting list users is within limits" do
      before do
        settings.update!(delayed_access_places: 10)
      end

      it_behaves_like "promotes waiting list users", 3
    end

    context "when the number of delayed_access_places is limited" do
      before do
        settings.update!(delayed_access_places: 2)
      end

      it_behaves_like "promotes waiting list users", 2

      it "outputs number of promoted users" do
        expect { Rake::Task[task_name].invoke }.to output("Promoted 2 user(s)\n").to_stdout
      end
    end

    context "when the number of waiting list users exceeds the batch size" do
      before do
        settings.update!(delayed_access_places: 10, waiting_list_promotions_per_run: 1)
      end

      it_behaves_like "promotes waiting list users", 1
    end

    context "when public access is disabled" do
      before do
        settings.update!(public_access_enabled: false)
      end

      it "exits with a message" do
        expect { Rake::Task[task_name].invoke }
          .to output("Not promoting while public access is disabled\n").to_stdout
          .and not_change(EarlyAccessUser, :count)
      end
    end

    context "when there are no delayed access places available" do
      before do
        settings.update!(delayed_access_places: 0)
      end

      it "exits with a message" do
        expect { Rake::Task[task_name].invoke }
          .to output("No delayed access places available\n").to_stdout
          .and not_change(EarlyAccessUser, :count)
      end
    end

    context "when waiting list promotions per run is set to zero" do
      before do
        settings.update!(delayed_access_places: 5,
                         waiting_list_promotions_per_run: 0)
      end

      it "exits with a message" do
        expect { Rake::Task[task_name].invoke }
          .to output("Promotions per run set to zero\n").to_stdout
          .and not_change(EarlyAccessUser, :count)
      end
    end
  end
end
