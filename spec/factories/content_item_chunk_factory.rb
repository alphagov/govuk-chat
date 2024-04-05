FactoryBot.define do
  factory :content_item_chunk, class: "Chunking::ContentItemChunk" do
    skip_create

    transient do
      schema_name { "generic" }
      content_id { nil }
      locale { "en" }
      base_path { nil }
      title { nil }
    end

    content_item do
      schema = GovukSchemas::Schema.find(notification_schema: schema_name)
      GovukSchemas::RandomExample.new(schema:).payload.tap do |item|
        item["content_id"] = content_id if content_id
        item["locale"] = locale if locale
        item["base_path"] = base_path if base_path
        item["title"] = title if title
      end
    end

    html_content { "<p>Content</p>" }
    heading_hierarchy { ["Heading 1", "Heading 2"] }
    chunk_index { 0 }
    chunk_url { nil }

    initialize_with do
      new(content_item:,
          html_content:,
          heading_hierarchy:,
          chunk_index:,
          chunk_url:)
    end
  end
end
