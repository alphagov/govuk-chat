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
end
