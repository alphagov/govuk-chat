class MessageQueue::ContentSynchroniser
  Result = Data.define(:chunks_created, :chunks_updated, :chunks_deleted, :skip_index_reason) do
    include ActionView::Helpers::TextHelper

    def initialize(chunks_created: 0, chunks_updated: 0, chunks_deleted: 0, skip_index_reason: nil)
      super
    end

    def to_s
      if skip_index_reason
        "content not indexed (#{skip_index_reason}), " \
        "#{pluralize(chunks_deleted, 'chunk')} deleted"
      else
        "#{pluralize(chunks_created, 'chunk')} newly inserted, " \
        "#{pluralize(chunks_updated, 'chunk')} updated, " \
        "#{pluralize(chunks_deleted, 'chunk')} deleted"
      end
    end
  end
end
