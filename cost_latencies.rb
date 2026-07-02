#!/usr/bin/env ruby

require "json"
require "csv"

input_file = ARGV.first

unless File.exist?(input_file)
  puts "Missing input file #{input_file}"
  exit(1)
end

input_file_for_evaluation = "./eval_input.yaml"
File.delete(input_file_for_evaluation) if File.exist?(input_file_for_evaluation)

results = File.read(input_file).split("\n").map do |line|
  data = JSON.parse(line)

  File.open(input_file_for_evaluation, "a") do |f|
    f.puts "- #{data['question']}\n"
  end

  { question: data["question"], id: data["question_id"] }
end

# remove the last newline
content = File.read(input_file_for_evaluation).chomp
File.write(input_file_for_evaluation, content)

def run_evaluation(input_file, results)
  output_file = "/tmp/cost_latencies.jsonl"

  cmd = system("bundle exec rake evaluation:batch_process[generate_rag_structured_answer_response_cost_latencies] INPUT_PATH=#{input_file} OUTPUT_PATH=#{output_file} CONCURRENCY=10")

  unless cmd
    puts "Failed to run evaluation"
    exit(1)
  end

  eval_results = File.read(output_file)

  eval_results.split("\n").map do |result|
    data = JSON.parse(result)
    metrics = data.dig("output", "metrics")

    question_data = results.find { |question| question[:question] == data["input"] }

    run_data = {
      id: question_data[:id],
      question: data["input"],
      answer: data.dig("output", "message"),
      question_routing_duration: metrics.dig("question_routing", "duration"),
      question_routing_cached_input_tokens: metrics.dig("question_routing", "llm_cached_tokens") || 0,
      question_routing_uncached_input_tokens: metrics.dig("question_routing", "llm_prompt_tokens"),
      question_routing_output_tokens: metrics.dig("question_routing", "llm_completion_tokens"),

      question_rephrasing_duration: metrics.dig("question_rephrasing", "duration"),
      question_rephrasing_cached_input_tokens: metrics.dig("question_rephrasing", "llm_cached_tokens") || 0,
      question_rephrasing_uncached_input_tokens: metrics.dig("question_rephrasing", "llm_prompt_tokens"),
      question_rephrasing_output_tokens: metrics.dig("question_rephrasing", "llm_completion_tokens"),

      search_results_duration: metrics.dig("search_results", "duration"),

      structured_answer_duration: metrics.dig("structured_answer", "duration"),
      structured_answer_cached_input_tokens: metrics.dig("structured_answer", "llm_cached_tokens") || 0,
      structured_answer_uncached_input_tokens: metrics.dig("structured_answer", "llm_prompt_tokens"),
      structured_answer_output_tokens: metrics.dig("structured_answer", "llm_completion_tokens"),
    }
    question_data[:runs] ||= []
    question_data[:runs] << run_data
  end

  File.delete(output_file)
end

3.times do |i|
  puts "====== Run #{i + 1} ======"
  run_evaluation(input_file_for_evaluation, results)
  puts ""
end

output_file = "./cost_latencies.csv"

headers = %w[id question answer question_routing_duration question_routing_cached_input_tokens question_routing_uncached_input_tokens question_routing_output_tokens question_rephrasing_duration question_rephrasing_cached_input_tokens question_rephrasing_uncached_input_tokens question_rephrasing_output_tokens search_results_duration structured_answer_duration structured_answer_cached_input_tokens structured_answer_uncached_input_tokens structured_answer_output_tokens]

CSV.open(output_file, "w") do |csv|
  csv << headers
  results.each do |question|
    question[:runs].each do |run|
      csv << CSV::Row.new(run.keys, run.values)
    end
  end
end

File.delete(input_file_for_evaluation)
puts "Written results to #{output_file}"
