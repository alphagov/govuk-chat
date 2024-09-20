namespace :settings do
  desc "Increments the places settings"
  task :increment_pilot_places, %i[places_type] => :environment do |_, args|
    unless %w[instant_access delayed_access].include?(args.places_type)
      abort("Only accepted args are instant_access and delayed_access for places_type")
    end

    config = Rails.configuration.public_send("#{args.places_type}_places_schedule".to_sym)

    if !config.places || config.places.negative?
      abort("places must be defined and not be a negative number")
    end

    unless config.max_places&.positive?
      abort("max_places must be defined and be a positive integer")
    end

    if config.places.zero?
      next puts "places are set to be incremented by zero, nothing to do"
    end

    not_before_date = config.not_before
    if not_before_date && Time.current < not_before_date
      next puts "This task is not available before #{not_before_date.to_fs(:date)}"
    end

    not_after_date = config.not_after
    if not_after_date && Time.current > not_after_date
      next puts "This task is not available after #{not_after_date.to_fs(:date)}"
    end

    settings = Settings.instance

    settings.with_lock do
      attribute = "#{args.places_type}_places".to_sym
      current_places = settings[attribute]
      increment_amount = config.places
      max_places = config.max_places
      actual_increment = increment_amount + current_places <= max_places ? increment_amount : max_places - current_places
      humanised_attribute = attribute.to_s.humanize

      if !actual_increment.positive?
        next puts "#{humanised_attribute} is already at the maximum of #{max_places}"
      elsif actual_increment != increment_amount
        puts "Incrementing #{humanised_attribute.downcase} by #{actual_increment} to reach the maximum of #{max_places} places"
      else
        puts "Incrementing #{humanised_attribute.downcase} by #{increment_amount}"
      end

      settings[attribute] += actual_increment
      settings.save!
      SettingsAudit.create!(action: "#{humanised_attribute} incremented by #{actual_increment} via scheduled task")
    end
  end
end
