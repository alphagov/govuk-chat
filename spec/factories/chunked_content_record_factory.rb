FactoryBot.define do
  factory :chunked_content_record, class: "Hash" do
    skip_create

    chunk_index { 0 }
    html_content { "<p>Some content</p>" }
    content_id { SecureRandom.uuid }
    heading_hierarchy { ["Heading 1", "Heading 2"] }
    digest { Digest::SHA2.new(256).hexdigest(rand.to_s) }
    base_path { "/base-path" }
    exact_path { "/base-path#anchor" }
    locale { "en" }
    document_type { "guide" }
    parent_document_type { nil }
    title { "Title" }
    description { "Description" }
    plain_content { "Some content" }
    openai_embedding { [rand(-0.9...0.9)] * Search::ChunkedContentRepository::OPENAI_EMBEDDING_DIMENSIONS }

    initialize_with { attributes }
  end
end
