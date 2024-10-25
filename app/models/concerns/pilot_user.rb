module PilotUser
  extend ActiveSupport::Concern

  included do
    user_research_questions = Rails.configuration.pilot_user_research_questions
    user_description_values = user_research_questions.user_description.options.map(&:value)
    enum :user_description, user_description_values.index_by(&:to_sym), prefix: true

    reason_for_visit_values = user_research_questions.reason_for_visit.options.map(&:value)
    enum :reason_for_visit, reason_for_visit_values.index_by(&:to_sym), prefix: true
  end
end
