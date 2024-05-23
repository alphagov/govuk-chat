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
  end
end
