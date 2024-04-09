module MessageQueue
  class ContentSynchroniser
    def self.call(...) = new(...).call

    def initialize(content_item)
      @content_item = content_item
    end

    def call
      if non_english_locale?
        return delete_with_skip_index_reason("has a non-English locale")
      end

      unless supported_schema?
        return delete_with_skip_index_reason(%(uses schema "#{schema_name}"))
      end

      if withdrawn?
        return delete_with_skip_index_reason("is withdrawn")
      end

      IndexContentItem.call(content_item, chunked_content_repository)
    end

  private

    attr_reader :content_item

    def chunked_content_repository
      @chunked_content_repository ||= Search::ChunkedContentRepository.new
    end

    def delete_with_skip_index_reason(skip_index_reason)
      chunks_deleted = chunked_content_repository.delete_by_base_path(content_item["base_path"])
      Result.new(chunks_deleted:, skip_index_reason:)
    end

    def schema_name
      content_item["schema_name"]
    end

    def non_english_locale?
      content_item["locale"] != "en"
    end

    def supported_schema?
      Chunking::ContentItemToChunks.supported_schemas.include?(schema_name)
    end

    def withdrawn?
      content_item["withdrawn_notice"].present?
    end
  end
end
