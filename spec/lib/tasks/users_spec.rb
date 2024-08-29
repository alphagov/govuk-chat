RSpec.describe "users rake tasks" do
  describe "users:promote_waiting_list" do
    let(:task_name) { "users:promote_waiting_list" }
    let!(:waiting_list_users) { create_list :waiting_list_user, 3 }
    let(:early_access_users) { EarlyAccessUser.all }

    before do
      Rake::Task[task_name].reenable
    end

    shared_examples "makes the correct changes" do |expected_promotions|
      it "add EarlyAccessUsers and deletes WaitingListUsers" do
        expect { Rake::Task[task_name].invoke }.to change(EarlyAccessUser, :count).by(expected_promotions)
          .and change(WaitingListUser, :count).by(-expected_promotions)
      end

      it "copies the attributes across correctly" do
        Rake::Task[task_name].invoke
        expected = waiting_list_users.take(expected_promotions).map { |u| [u.email, u.user_description, u.reason_for_visit] }
        actual = early_access_users.pluck(:email, :user_description, :reason_for_visit)
        expect(actual).to eq(expected)
      end

      it "locks the settings and decrements the available places" do
        settings = create :settings, delayed_access_places: expected_promotions
        allow(Settings).to receive(:instance).and_return(settings)
        expect(settings).to receive(:with_lock).and_call_original
        expect { Rake::Task[task_name].invoke }.to change(settings, :delayed_access_places).by(-expected_promotions)
      end
    end

    context "when number of waiting list users is within limits" do
      before do
        settings = create :settings
        allow(Settings).to receive(:instance).and_return(settings)
      end

      it_behaves_like "makes the correct changes", 3
    end

    context "when the number of delayed_access_places is limited" do
      before do
        settings = create :settings, delayed_access_places: 2
        allow(Settings).to receive(:instance).and_return(settings)
      end

      it_behaves_like "makes the correct changes", 2
    end

    context "when the number of waiting list users exceeds the batch size" do
      before do
        settings = create :settings, delayed_access_places: 50
        allow(Settings).to receive(:instance).and_return(settings)
        allow(Rails.configuration.early_access_users).to receive(:max_waiting_list_promotions_per_run).and_return(1)
      end

      it_behaves_like "makes the correct changes", 1
    end

    context "when there are delayed access places available" do
      before do
        settings = create :settings, delayed_access_places: 0
        allow(Settings).to receive(:instance).and_return(settings)
      end

      it "does not continue processing" do
        expect(Rails.configuration).not_to receive(:early_access_users)
        expect { Rake::Task[task_name].invoke }.to output("No delayed access places available\n").to_stdout
      end
    end
  end
end
