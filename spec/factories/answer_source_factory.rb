FactoryBot.define do
  factory :answer_source do
    answer
    chunk(factory: :answer_source_chunk)
    sequence(:relevancy) { |n| n }
    sequence(:base_path) { |n| "/base_path/#{n}" }
    sequence(:exact_path) { |n| "#{base_path}/path/#{n}" }
    sequence(:title) { |n| "Title #{n}" }
    sequence(:heading) { |n| "Heading #{n}" }
    content_chunk_id { "#{SecureRandom.uuid}_en_0" }
    content_chunk_digest { Digest::SHA2.new(256).hexdigest(rand.to_s) }
  end
end
