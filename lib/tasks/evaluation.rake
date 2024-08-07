namespace :evaluation do
  desc "Export JSONL data for auto-evaluation"
  task :generate_report, %i[output_path] => :environment do |_, args|
    output_path = args[:output_path]

    ENV["GOVUK_WEBSITE_ROOT"] ||= "https://www.gov.uk"

    results = Evaluation::ReportGenerator.call do |total, current, evaluation_question|
      puts "(#{current} / #{total}): #{evaluation_question}"
    end

    jsonl = results.map(&:to_json).join("\n")

    if output_path.present?
      File.open(output_path, "wb") { |file| file.write(jsonl) }
      puts "Written to #{output_path}"
    else
      puts jsonl
    end
  end

  desc "Export CSV for HMRC evaluation"
  task :generate_hmrc_report, %i[output_path] => :environment do |_, args|
    output_path = args[:output_path]

    ENV["GOVUK_WEBSITE_ROOT"] ||= "https://www.gov.uk"

    results = Evaluation::HmrcReportGenerator.call do |total, current, evaluation_question|
      puts "(#{current} / #{total}): #{evaluation_question}"
    end

    if output_path.present?
      CSV.open(output_path, "w") do |csv|
        results.each do |row|
          csv << row
        end
      end
      puts "Written to #{output_path}"
    else
      puts results.to_csv
    end
  end
end
