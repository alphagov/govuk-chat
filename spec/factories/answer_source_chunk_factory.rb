FactoryBot.define do
  factory :answer_source_chunk do
    base_path { "/base-path" }
    chunk_index { 0 }
    content_id { SecureRandom.uuid }
    description { "Description" }
    digest { Digest::SHA2.new(256).hexdigest(rand.to_s) }
    document_type { "guide" }
    exact_path { "#{base_path}#anchor" }
    heading_hierarchy { ["Heading 1", "Heading 2"] }
    html_content { "<p>Some content</p>" }
    locale { "en" }
    parent_document_type { nil }
    plain_content { "Some content" }
    title { "Title" }
  end
end
