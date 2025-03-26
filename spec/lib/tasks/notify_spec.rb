RSpec.describe "Notify tasks" do
  describe "notify:send_email" do
    let(:email_address) { "x@y.com" }
    let(:template_id) { SecureRandom.uuid }

    before { Rake::Task["notify:send_email"].reenable }

    around do |example|
      ClimateControl.modify GOVUK_NOTIFY_TEMPLATE_ID: template_id do
        example.run
      end
    end

    it "sends an email notification via GOV.UK Notify" do
      expect { Rake::Task["notify:send_email"].invoke(email_address) }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "raises an error if email address is not present" do
      ClimateControl.modify EMAIL_ADDRESS_OVERRIDE: nil do
        expect { Rake::Task["notify:send_email"].invoke }
          .to raise_error("Missing email address")
      end
    end

    it "raises an error when GOVUK_NOTIFY_TEMPLATE_ID is not set" do
      ClimateControl.modify GOVUK_NOTIFY_TEMPLATE_ID: nil do
        expect { Rake::Task["notify:send_email"].invoke(email_address) }
          .to raise_error(KeyError, /GOVUK_NOTIFY_TEMPLATE_ID/)
      end
    end

    it "uses default values if optional values not provided" do
      Rake::Task["notify:send_email"].invoke(email_address)
      message = ActionMailer::Base.deliveries.last

      personalisations = message.personalisation
      expect(personalisations[:subject]).to eq("Test email notification")
      expect(personalisations[:body]).to eq("Test email notification")
    end
  end
end
