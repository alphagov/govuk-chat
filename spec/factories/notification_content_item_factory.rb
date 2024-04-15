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
    title { :preserve }
    withdrawn { false }
    payload_version { :preserve }

    transient do
      # This value is used to determine whether a built schema is validated
      # as part of creation (see after(:build) callback)
      ensure_valid { true }
      body { nil }
      details { nil }
      details_merge { nil }
    end

    initialize_with do
      schema = GovukSchemas::Schema.find(notification_schema: schema_name)
      GovukSchemas::RandomExample.new(schema:).payload.tap do |item|
        %i[content_id locale base_path title payload_version].each do |field|
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
      end
    end

    after(:build) do |item, evaluator|
      next unless evaluator.ensure_valid

      validator = GovukSchemas::Validator.new(evaluator.schema_name, "notification", item)

      unless validator.valid?
        error_message =  "Factory bot has produced a content item that is no longer\n" \
                         "if this is intentional pass in ensure_valid: false to the " \
                         "factory\n\n" + validator.error_message
        raise error_message
      end
    end
  end
end
