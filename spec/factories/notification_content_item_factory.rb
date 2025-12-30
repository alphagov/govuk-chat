require "govuk_schemas/validator"

FactoryBot.define do
  factory :notification_content_item, class: "Hash" do
    skip_create

    schema_name { "generic" }

    # The following attributes accept :preserve as a value which indicates that
    # we want to keep whatever the random schema generator creates.
    content_id { :preserve }
    locale { "en" }
    base_path { :preserve }
    document_type { :preserve }
    title { :preserve }
    description { :preserve }
    withdrawn { false }
    payload_version { :preserve }

    transient do
      # This value is used to determine whether a built schema is validated
      # after modification
      ensure_valid { true }
      body { nil }
      details { nil }
      details_merge { nil }
      parent_document_type { :preserve }
      current_government { :preserve }
    end

    initialize_with do
      schema = GovukSchemas::Schema.find(notification_schema: schema_name)
      modify_item = proc do |item|
        %i[content_id locale base_path document_type title description payload_version].each do |field|
          item[field.to_s] = attributes[field] unless attributes[field] == :preserve
        end

        if withdrawn
          item["withdrawn_notice"] = {
            "explanation" => "Reason why this was withdrawn",
            "withdrawn_at": "2023-02-03T07:35:00Z",
          }
        elsif withdrawn != :preserve
          item.delete("withdrawn_notice")
        end

        if [body, details, details_merge].compact.length > 1
          raise "This factory can only accept one of body, details and details_merge"
        end

        item["details"]["body"] = body if body
        item["details"] = details if details
        item["details"] = item["details"].merge(details_merge) if details_merge

        if parent_document_type && parent_document_type != :preserve
          item["expanded_links"]["parent"] = [
            {
              "base_path" => "/parent",
              "content_id" => SecureRandom.uuid,
              "locale" => "en",
              "title" => "Parent title",
              "document_type" => parent_document_type,
            },
          ]
        end
        item["expanded_links"].delete("parent") if parent_document_type.nil?

        if !current_government.nil? && current_government != :preserve
          item["expanded_links"]["government"] = [
            {
              "base_path" => "/government",
              "content_id" => SecureRandom.uuid,
              "locale" => "en",
              "title" => "Government name",
              "document_type" => "government",
              "details" => {
                "current" => current_government,
                "ended_on" => nil,
                "started_on": "2015-05-08T00:00:00+00:00",
              },
            },
          ]
        end
        item["expanded_links"].delete("government") if current_government.nil?
        item
      end

      if ensure_valid
        # payload implicitly validates the modified content item
        GovukSchemas::RandomExample.new(schema:).payload(&modify_item)
      else
        item = GovukSchemas::RandomExample.new(schema:).payload
        modify_item.call(item)
      end
    end

    trait :answer do
      schema_name { "answer" }
      document_type { "answer" }
      body do
        [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }]
      end
    end

    trait :corporate_information_page do
      schema_name { "corporate_information_page" }
      document_type { "about" }
    end

    trait :detailed_guide do
      schema_name { "detailed_guide" }
      document_type { "detailed_guide" }
    end

    trait :guide do
      schema_name { "guide" }
      document_type { "guide" }
      details_merge do
        {
          "parts" => [
            {
              "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }],
              "title" => "Part 1",
              "slug" => "part-1",
            },
          ],
        }
      end
    end

    trait :help_page do
      schema_name { "help_page" }
      document_type { "help_page" }
      body do
        [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }]
      end
    end

    trait :html_publication do
      schema_name { "html_publication" }
      document_type { "html_publication" }
      parent_document_type { "form" }
    end

    trait :manual do
      schema_name { "manual" }
      document_type { "manual" }
      body do
        [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }]
      end
    end

    trait :manual_section do
      schema_name { "manual_section" }
      document_type { "manual_section" }
      body do
        [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }]
      end
    end

    trait :publication do
      schema_name { "publication" }
      document_type { "form" }
    end

    trait :service_manual_guide do
      schema_name { "service_manual_guide" }
      document_type { "service_manual_guide" }
    end

    trait :simple_smart_answer do
      schema_name { "simple_smart_answer" }
      document_type { "simple_smart_answer" }
      body do
        [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }]
      end
    end

    trait :specialist_document do
      schema_name { "specialist_document" }
      document_type { "business_finance_support_scheme" }
      body do
        [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }]
      end
    end

    trait :step_by_step_nav do
      schema_name { "step_by_step_nav" }
      document_type { "step_by_step_nav" }
      details do
        {
          "step_by_step_nav" => {
            "title" => "Some title",
            "introduction" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }],
            "steps" => [
              {
                "title" => "Step 1",
                "contents" => [{ "type" => "paragraph", "text" => "Some content" }],
              },
              {
                "title" => "Step 2",
                "contents" => [{ "type" => "paragraph", "text" => "Some other content" }],
              },
            ],
          },
        }
      end
    end

    trait :take_part do
      schema_name { "take_part" }
      document_type { "take_part" }
    end

    trait :transaction do
      schema_name { "transaction" }
      document_type { "transaction" }
      details do
        {
          "introductory_paragraph" => [{ "content_type" => "text/html", "content" => "<p>Intro</p>" }],
          "more_information" => [{ "content_type" => "text/html", "content" => "<p>More info</p>" }],
        }
      end
    end

    trait :travel_advice do
      schema_name { "travel_advice" }
      document_type { "travel_advice" }
      details_merge do
        {
          "parts" => [
            {
              "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }],
              "title" => "Part 1",
              "slug" => "part-1",
            },
          ],
        }
      end
    end

    trait :worldwide_corporate_information_page do
      schema_name { "worldwide_corporate_information_page" }
      document_type { "modern_slavery_statement" }
      body { "<p>Some content</p>" }
    end

    trait :worldwide_organisation do
      schema_name { "worldwide_organisation" }
      document_type { "worldwide_organisation" }
      body { "<p>Some content</p>" }
    end
  end
end
