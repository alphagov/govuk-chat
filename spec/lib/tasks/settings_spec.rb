RSpec.describe "rake search tasks" do
  describe "settings:increment_pilot_places" do
    let(:task_name) { "settings:increment_pilot_places" }
    let!(:settings) { create(:settings) }
    let(:one_day_ago) { 1.day.ago.to_date }
    let(:one_day_from_now) { 1.day.from_now.to_date }
    let(:instant_access_places_schedule) { Rails.configuration.instant_access_places_schedule }

    before do
      allow(Settings).to receive(:instance).and_return(settings)
      allow(instant_access_places_schedule)
        .to receive_messages(not_before: nil, not_after: nil, max_places: 150, places: 5)
      Rake::Task[task_name].reenable
    end

    context "when given a places_type of 'instant_access'" do
      it "updates the settings.instant_access_places attribute" do
        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output("Incrementing instant access places by 5\n").to_stdout
          .and change(settings, :instant_access_places).by(5)
      end
    end

    context "when given a places_type of 'delayed_access'" do
      before do
        allow(Rails.configuration.delayed_access_places_schedule)
          .to receive_messages(not_before: nil, not_after: nil, max_places: 150, places: 5)
      end

      it "updates the settings.delayed_access_places attribute" do
        expect { Rake::Task[task_name].invoke("delayed_access") }
          .to output("Incrementing delayed access places by 5\n").to_stdout
          .and change(settings, :delayed_access_places).by(5)
      end
    end

    context "when given a different value of places_type" do
      it "aborts with an error message" do
        expect { Rake::Task[task_name].invoke("invalid_arg") }
          .to output(/Only accepted args are instant_access and delayed_access for places_type\n/).to_stderr
          .and raise_error(SystemExit)
      end
    end

    it "errors when the places config variable is not set or not a positive number" do
      [nil, 0, -5].each do |value|
        Rake::Task[task_name].reenable
        allow(instant_access_places_schedule).to receive(:places).and_return(value)
        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output(/places must be defined and be a positive integer\n/).to_stderr
          .and raise_error(SystemExit)
      end
    end

    it "errors when the max_places config variable is not set or not a positive number" do
      [nil, 0, -5].each do |value|
        Rake::Task[task_name].reenable
        allow(instant_access_places_schedule).to receive(:max_places).and_return(value)
        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output(/max_places must be defined and be a positive integer\n/).to_stderr
          .and raise_error(SystemExit)
      end
    end

    it "doesn't increment places before the 'not_before' date" do
      freeze_time do
        allow(instant_access_places_schedule)
          .to receive_messages(not_before: one_day_from_now, not_after: one_day_from_now)

        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output("This task is not available before #{one_day_from_now.to_fs(:date)}\n").to_stdout
      end
    end

    it "doesn't increment places after the 'not_after' date" do
      freeze_time do
        allow(instant_access_places_schedule)
          .to receive_messages(not_before: one_day_ago, not_after: one_day_ago)

        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output("This task is not available after #{one_day_ago.to_fs(:date)}\n").to_stdout
      end
    end

    it "locks the settings record to update the places" do
      expect(settings).to receive(:with_lock).and_call_original
      Rake::Task[task_name].invoke("instant_access")
    end

    it "creates a SettingsAudit record to communicate what has been done" do
      expect { Rake::Task[task_name].invoke("instant_access") }
        .to output("Incrementing instant access places by 5\n").to_stdout
        .and change(SettingsAudit, :count).by(1)
      expect(SettingsAudit.last.action).to eq "Instant access places incremented by 5 via scheduled task"
    end

    context "when the places increment would not bring the total above the max places value" do
      it "updates the setting by the increment value" do
        settings.update!(instant_access_places: 0)
        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output("Incrementing instant access places by 5\n").to_stdout
          .and change(settings, :instant_access_places).by(5)
      end
    end

    context "when the places increment would bring the total above the max places value" do
      it "updates the setting to the max places value" do
        max_places = instant_access_places_schedule.max_places
        settings.update!(instant_access_places: max_places - 4)

        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output("Incrementing instant access places by 4 to reach the maximum of #{max_places} places\n").to_stdout
          .and change(settings, :instant_access_places).by(4)
      end
    end

    context "when max_places has already been reached" do
      it "exits without updating the setting" do
        max_places = instant_access_places_schedule.max_places
        settings.update!(instant_access_places: max_places)

        expect { Rake::Task[task_name].invoke("instant_access") }
          .to output("Instant access places is already at the maximum of #{max_places}\n").to_stdout
          .and(not_change { settings.instant_access_places })
      end
    end
  end
end
