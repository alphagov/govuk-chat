FactoryBot.define do
  factory :content_item, class: "Hash" do
    skip_create

    initialize_with { attributes.stringify_keys }

    trait :answer do
      schema_name { "answer" }
      document_type { "answer" }
      details do
        { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] }
      end
    end

    trait :corporate_information_page do
      schema_name { "corporate_information_page" }
      document_type { "about" }
      details do
        { "body" => "<p>Some content</p>" }
      end
    end

    trait :detailed_guide do
      schema_name { "detailed_guide" }
      document_type { "detailed_guide" }
      details do
        { "body" => "<p>Some content</p>" }
      end
    end

    trait :guide do
      schema_name { "guide" }
      document_type { "guide" }
      details do
        {
          "parts" => [
            { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] },
          ],
        }
      end
    end

    trait :help_page do
      schema_name { "help_page" }
      document_type { "help_page" }
      details do
        { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] }
      end
    end

    trait :html_publication do
      schema_name { "html_publication" }
      document_type { "html_publication" }
      expanded_links do
        { "parent" => [{ "document_type" => "form" }] }
      end
      details do
        { "body" => "<p>Some content</p>" }
      end
    end

    trait :manual do
      schema_name { "manual" }
      document_type { "manual" }
      details do
        { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] }
      end
    end

    trait :manual_section do
      schema_name { "manual_section" }
      document_type { "manual_section" }
      details do
        { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] }
      end
    end

    trait :publication do
      schema_name { "publication" }
      document_type { "form" }
      details do
        { "body" => "<p>Some content</p>" }
      end
    end

    trait :service_manual_guide do
      schema_name { "service_manual_guide" }
      document_type { "service_manual_guide" }
      details do
        { "body" => "<p>Some content</p>" }
      end
    end

    trait :simple_smart_answer do
      schema_name { "simple_smart_answer" }
      document_type { "simple_smart_answer" }
      details do
        { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] }
      end
    end

    trait :specialist_document do
      schema_name { "specialist_document" }
      document_type { "business_finance_support_scheme" }
      details do
        { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] }
      end
    end

    trait :step_by_step_nav do
      schema_name { "step_by_step_nav" }
      document_type { "step_by_step_nav" }
      details do
        {
          "step_by_step_nav" => {
            "introduction" => [{ "content" => "<p>Some content</p>" }],
            "steps" => [
              {
                "logic" => "or",
                "contents" => [{ "type" => "paragraph", "text" => "<p>Some content</p>" }],
              },
              {
                "logic" => "or",
                "contents" => [{ "type" => "paragraph", "text" => "<p>Some other content</p>" }],
              },
            ],
          },
        }
      end
    end

    trait :take_part do
      schema_name { "take_part" }
      document_type { "take_part" }
      details do
        { "body" => "<p>Some content</p>" }
      end
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
      details do
        {
          "alert_status" => [],
          "parts" => [
            { "body" => [{ "content_type" => "text/html", "content" => "<p>Some content</p>" }] },
          ],
        }
      end
    end

    trait :worldwide_corporate_information_page do
      schema_name { "worldwide_corporate_information_page" }
      document_type { "modern_slavery_statement" }
      details do
        { "body" => "<p>Some content</p>" }
      end
    end

    trait :worldwide_organisation do
      schema_name { "worldwide_organisation" }
      document_type { "worldwide_organisation" }
      details do
        { "body" => "<p>Some content</p>" }
      end
    end
  end
end
