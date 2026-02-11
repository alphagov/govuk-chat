FactoryBot.define do
  factory :content_item_chunk, class: "Chunking::ContentItemChunk" do
    skip_create

    transient do
      schema_name { "generic" }
      content_id { :preserve }
      locale { "en" }
      base_path { :preserve }
      title { :preserve }
      description { :preserve }
      parent_document_type { :preserve }
    end

    content_item do
      build(:notification_content_item,
            schema_name:,
            content_id:,
            locale:,
            base_path:,
            title:,
            description:,
            parent_document_type:)
    end

    html_content { "<p>Content</p>" }
    heading_hierarchy { ["Heading 1", "Heading 2"] }
    chunk_index { 0 }
    exact_path { nil }
    llm_instructions { nil }

    initialize_with do
      new(content_item:,
          html_content:,
          heading_hierarchy:,
          chunk_index:,
          exact_path:,
          llm_instructions:)
    end
  end
end
