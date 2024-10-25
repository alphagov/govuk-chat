module PilotUserExamples
  shared_examples "underlying enum matches config" do |db_enum_name, ar_enum_name|
    it "has matching values for the Model.#{ar_enum_name} and the DB enum #{db_enum_name}" do
      query = "SELECT enumlabel FROM pg_enum WHERE enumtypid = $1::regtype"
      db_values = ActiveRecord::Base.connection.exec_query(query, "SQL", [db_enum_name]).rows.flatten
      ar_values = described_class.public_send(ar_enum_name.to_sym).keys.map(&:to_s)
      expect(db_values).to match_array(ar_values)
    end
  end

  shared_examples "user research question enums match config" do
    include_examples "underlying enum matches config", "ur_question_user_description", :user_descriptions
    include_examples "underlying enum matches config", "ur_question_reason_for_visit", :reason_for_visits
  end
end
