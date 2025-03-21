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

      unless supported_content_item?
        return delete_with_skip_index_reason(non_indexable_content_item_reason)
      end

      if withdrawn?
        return delete_with_skip_index_reason("is withdrawn")
      end

      if history_mode?
        return delete_with_skip_index_reason("is in history mode")
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

    def supported_content_item?
      Chunking::ContentItemToChunks.supported_content_item?(content_item)
    end

    def non_indexable_content_item_reason
      Chunking::ContentItemToChunks.non_indexable_content_item_reason(content_item)
    end

    def non_english_locale?
      content_item["locale"] != "en"
    end

    def withdrawn?
      content_item["withdrawn_notice"].present?
    end

    def history_mode?
      return unless content_item.dig("details", "political") == true

      content_item.dig("expanded_links", "government", 0, "details", "current") == false
    end
  end
end
