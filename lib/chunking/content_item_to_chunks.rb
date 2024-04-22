module Chunking
  class ContentItemToChunks
    PARSERS_FOR_SCHEMAS = {
      ContentItemParsing::BodyContentParser => %w[answer
                                                  call_for_evidence
                                                  consultation
                                                  detailed_guide
                                                  help_page
                                                  hmrc_manual_section
                                                  history
                                                  manual
                                                  manual_section
                                                  news_article
                                                  publication
                                                  service_manual_guide],
      ContentItemParsing::GuideParser => %w[guide],
      ContentItemParsing::TransactionParser => %w[transaction],
      # TODO: establish all supported schemas and add parsers for them
    }.freeze

    def self.call(content_item)
      schema_name = content_item["schema_name"]
      parser_class = PARSERS_FOR_SCHEMAS.find { |_, v| v.include?(schema_name) }&.first

      raise "No content item parser configured for #{schema_name}" unless parser_class

      parser_class.call(content_item)
    end

    def self.supported_schema_and_document_type?(schema_name, document_type)
      case schema_name
      when "publication"
        %w[correspondence decision].exclude?(document_type)
      else
        supported_schemas.include?(schema_name)
      end
    end

    def self.supported_schemas
      PARSERS_FOR_SCHEMAS.values.flatten
    end
  end
end
