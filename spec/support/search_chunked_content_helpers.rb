module SearchChunkedContentHelpers
  def populate_chunked_content_index(chunks)
    body = if chunks.is_a?(Array)
             chunks.map { |chunk| { create: { data: chunk } } }
           else
             chunks.map { |id, chunk| { create: { _id: id, data: chunk } } }
           end

    chunked_content_search_client.bulk(index: chunked_content_index,
                                       body:,
                                       refresh: true)
  end

  def chunked_content_search_client
    @chunked_content_search_client ||= Search::ChunkedContentRepository.new.client
  end

  def chunked_content_index
    @chunked_content_index ||= Search::ChunkedContentRepository.new.index
  end
end
