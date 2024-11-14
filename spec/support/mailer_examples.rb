module MailerExamples
  shared_examples "sets reply_to_id" do
    it "sets reply_to_id to ENV[GOVUK_NOTIFY_REPLY_TO_ID]" do
      ClimateControl.modify GOVUK_NOTIFY_REPLY_TO_ID: "random-uuid" do
        expect(email.reply_to_id).to eq("random-uuid")
      end
    end
  end
end
