FactoryBot.define do
  factory :bigquery_export do
    exported_until { Time.current }
  end
end
