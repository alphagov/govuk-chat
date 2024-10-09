module PilotUser
  extend ActiveSupport::Concern

  USER_RESEARCH_QUESTION_DESCRIPTION = "Which of the following best describes you?".freeze
  USER_RESEARCH_QUESTION_REASON_FOR_VISIT = "Why did you visit GOV.UK today?".freeze

  included do
    enum :user_description,
         {
           business_owner_or_self_employed: "business_owner_or_self_employed",
           starting_business_or_becoming_self_employed: "starting_business_or_becoming_self_employed",
           business_advisor: "business_advisor",
           business_administrator: "business_administrator",
           none: "none",
         },
         prefix: true

    enum :reason_for_visit,
         {
           find_specific_answer: "find_specific_answer",
           complete_task: "complete_task",
           understand_process: "understand_process",
           research_topic: "research_topic",
           other: "other",
         },
         prefix: true
  end
end
