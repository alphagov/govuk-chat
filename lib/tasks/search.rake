namespace :search do
  desc "Create an index for chunked_content"
  task create_chunked_content_index: :environment do
    puts "Creating chunked content index"
    Search::ChunkedContentRepository.new.create_index
    puts "Index created"
  rescue OpenSearch::Transport::Transport::Errors::BadRequest => e
    # Using a regex as the message is a JSON object as a string
    raise e unless e.message.match?(/resource_already_exists/)

    puts "Index already exists run rake search:recreate_chunked_content_index to recreate it"
  end

  desc "Delete an existing chunked content opensearch index and create a new one"
  task recreate_chunked_content_index: :environment do
    if Rails.env.production?
      puts "This task has been disabled for production environments"
      exit 1
    end

    puts "Recreating chunked content index"
    Search::ChunkedContentRepository.new.create_index!
    puts "Index created"
  end

  desc "Update the chunked context index mappings"
  task update_chunked_content_mappings: :environment do
    puts "Adding missing content mappings"

    mappings = Search::ChunkedContentRepository.new.update_missing_mappings

    if mappings.present?
      puts "Mapping(s) added for: #{mappings.join(', ')}"
    else
      puts "No mappings were added"
    end
  end

  desc "Populate the Chunked Content OpenSearchIndex with data from seed files"
  task populate_chunked_content_index_from_seeds: %i[environment create_chunked_content_index] do
    if Rails.env.production?
      puts "This task has been disabled for production environments"
      exit 1
    end

    content = Dir["db/chunked_content_seeds/*.yml"].flat_map { |file| YAML.load_file(file) }

    chunks = content.flat_map do |item|
      faux_content_item = item.except("chunks").merge(
        "content_id" => SecureRandom.uuid,
        "locale" => "en",
      )

      item["chunks"].map.with_index do |chunk, index|
        Chunking::ContentItemChunk.new(content_item: faux_content_item,
                                       html_content: chunk["html_content"],
                                       heading_hierarchy: chunk["heading_hierarchy"],
                                       chunk_index: index,
                                       exact_path: chunk["exact_path"])
      end
    end

    embeddings = Search::TextToEmbedding.call(chunks.map(&:plain_content))
    repository = Search::ChunkedContentRepository.new
    indexed = 0

    base_paths = chunks.map(&:base_path).uniq
    deleted = base_paths.inject(0) do |memo, base_path|
      memo + repository.delete_by_base_path(base_path)
    end

    puts "#{deleted} conflicting chunks deleted"

    chunks.each.with_index do |chunk, index|
      document = chunk.to_opensearch_hash.merge(
        titan_embedding: embeddings[index],
      )
      repository.index_document(chunk.id, document)
      indexed += 1
    end

    puts "#{indexed} chunks indexed"
  end

  # Temporary task - to remove after running in production
  desc "Backfill AnswerSourceChunk records with missing data"
  task backfill_answer_source_chunks: :environment do
    checked = 0
    updated = 0
    skipped_out_of_date = 0
    skipped_not_found = 0

    template = "Checked %{checked} records - updated %{updated}, out of date " \
               "%{skipped_out_of_date}, not found %{skipped_not_found}"

    AnswerSourceChunk.where(document_type: "").find_each do |chunk|
      if checked.positive? && (checked % 500).zero?
        message = sprintf(template, checked:, updated:, skipped_out_of_date:, skipped_not_found:)

        puts "Progress - #{message}"
      end

      checked += 1

      id = "#{chunk.content_id}_#{chunk.locale}_#{chunk.chunk_index}"

      repo = Search::ChunkedContentRepository.new
      search_result = repo.chunk(id)

      if search_result.digest == chunk.digest
        attributes = search_result.to_h.slice(:heading_hierarchy,
                                              :html_content,
                                              :plain_content,
                                              :document_type,
                                              :parent_document_type,
                                              :description)

        chunk.update!(attributes)
        updated += 1
      else
        skipped_out_of_date += 1
      end
    rescue Search::ChunkedContentRepository::NotFound
      skipped_not_found += 1
      next
    end

    message = sprintf(template, checked:, updated:, skipped_out_of_date:, skipped_not_found:)

    puts "Finished - #{message}"
  end
end
