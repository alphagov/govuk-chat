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

  desc "Remove all chunks configured to be excluded from the index"
  task delete_all_excluded_chunks: :environment do
    count = 0

    content_ids = Rails.configuration.govuk_chat_private.indexing_excluded_content_ids
    content_ids.each do |content_id|
      count += Search::ChunkedContentRepository.new.delete_by_content_id(content_id)
    end

    puts "#{count} chunks deleted"
  end

  desc "Print a list of document types that are indexed, use ANNOTATED=true for further details"
  task print_document_types: :environment do
    document_types_by_schema = Rails.application.config.search.document_types_by_schema
    document_type_data = document_types_by_schema.inject([]) do |memo, (schema_name, schema_rules)|
      memo += schema_rules["document_types"].flat_map do |(document_type, document_type_rules)|
        document_type_weighting = document_type_rules && document_type_rules[:weight]
        if document_type_rules && document_type_rules["requires_parent_document_type"]
          document_type_rules["requires_parent_document_type"].map do |parent_name, parent_rules|
            weighting = parent_rules && parent_rules[:weight] ? parent_rules[:weight] : document_type_weighting
            { document_type:, schema_name:, requires_parent_document_type: parent_name, weighting: }
          end
        else
          [{ document_type:, schema_name:, weighting: document_type_weighting }]
        end
      end

      next memo
    end

    if ENV["ANNOTATED"] == "true"
      puts "Document types (annotated) indexed by GOV.UK Chat:"
      annotated = document_type_data.map do |rules|
        annotation = "schema name: #{rules[:schema_name]}"

        if rules[:requires_parent_document_type]
          annotation += ", required parent document_type: #{rules[:requires_parent_document_type]}"
        end

        if rules[:weighting]
          annotation += ", weighting: #{rules[:weighting]}"
        end

        "- #{rules[:document_type]} (#{annotation})"
      end

      puts annotated.sort.join("\n")
    else
      puts "Document types indexed by GOV.UK Chat:"
      puts document_type_data.map { "- #{it[:document_type]}" }.uniq.sort.join("\n")
    end
  end
end
