RSpec.describe BigqueryExport do
  describe "database constraints" do
    it "raises an exception when saving a duplicate exported_until" do
      time = Time.current
      described_class.create!(exported_until: time)

      expect {
        described_class.create!(exported_until: time)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
