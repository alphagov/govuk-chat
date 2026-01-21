FactoryBot.define do
  factory :chunked_content_search_result, class: "Search::ChunkedContentRepository::Result" do
    skip_create

    score { 0.5 }
    chunk_index { 0 }
    html_content { "<p>Some content</p>" }
    content_id { SecureRandom.uuid }
    heading_hierarchy { ["Heading 1", "Heading 2"] }
    digest { Digest::SHA2.new(256).hexdigest(rand.to_s) }
    base_path { "/base-path" }
    exact_path { "#{base_path}#anchor" }
    locale { "en" }
    document_type { "guide" }
    parent_document_type { nil }
    title { "Title" }
    description { "Description" }
    plain_content { "Some content" }
    schema_name { "guide" }
    _id { "#{content_id}_#{locale}_#{chunk_index}" }

    initialize_with { new(**attributes) }

    factory :weighted_search_result, class: "Search::ResultsForQuestion::WeightedResult" do
      weighted_score { 1.5 }
      weighting { 1.0 }
      initialize_with do
        result_attributes = attributes.except(:weighted_score, :weighting)
        result = Search::ChunkedContentRepository::Result.new(**result_attributes)

        factory_attributes = attributes.slice(:weighted_score, :weighting).merge(result:)
        new(**factory_attributes)
      end
    end
  end
end
