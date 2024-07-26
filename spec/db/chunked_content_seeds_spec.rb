RSpec.describe "chunked_content_seeds" do
  let(:seed_data) do
    glob_path = Rails.root.join("db/chunked_content_seeds/*.yml")
    Dir[glob_path].flat_map { |file| YAML.load_file(file) }
  end

  specify "all seed data is in the correct structure" do
    # One or more path segments starting with a / and containing one or more
    # alphanumeric, underscore or dash characters
    base_path_pattern = /(\/(\w|-)+)+/
    base_path_regex = /\A#{base_path_pattern}\z/
    exact_path_regex = /\A#{base_path_pattern}(#(\w|-)+)?\z/

    chunk_match = match(
      "html_content" => instance_of(String),
      "heading_hierarchy" => all(match(instance_of(String))),
      "exact_path" => match(exact_path_regex),
    )

    expect(seed_data).to all(
      match(
        "base_path" => match(base_path_regex),
        "document_type" => instance_of(String),
        "title" => instance_of(String),
        "description" => satisfy { |d| d.nil? || d.is_a?(String) },
        "chunks" => all(chunk_match),
      ),
    )
  end

  specify "each item has a unique base_path" do
    dupes = seed_data.group_by { |item| item["base_path"] }
                     .select { |_, v| v.count > 1 }
                     .keys

    expect(dupes).to be_empty, "Duplicated base paths found in seed data: #{dupes.join(', ')}"
  end
end
