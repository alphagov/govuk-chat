FactoryBot.define do
  factory :chunked_content_record, class: "Hash" do
    skip_create

    chunk_index { 0 }
    html_content { "<p>Some content</p>" }
    content_id { SecureRandom.uuid }
    heading_hierarchy { ["Heading 1", "Heading 2"] }
    digest { Digest::SHA2.new(256).hexdigest(rand.to_s) }
    base_path { "/base-path" }
    locale { "en" }
    document_type { "guide" }
    title { "Title" }
    url { "/base-path#anchor" }
    plain_content { "Some content" }
    openai_embedding { [rand(-0.9...0.9)] * 1536 }

    initialize_with { attributes }
  end
end
