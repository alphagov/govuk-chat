module SearchChunkedContentHelpers
  def populate_chunked_content_index(record_or_records)
    actions = Array(record_or_records).map do |record|
      id = record.delete(:_id)
      create = { data: record }
      create[:_id] = id if id
      { create: }
    end

    chunked_content_search_client.bulk(index: chunked_content_index,
                                       body: actions,
                                       refresh: true)
  end

  def chunked_content_search_client
    @chunked_content_search_client ||= Search::ChunkedContentRepository.new.client
  end

  def chunked_content_index
    @chunked_content_index ||= Search::ChunkedContentRepository.new.index
  end
end
