class WaitingListUser < ApplicationRecord
  enum :source,
       {
         admin_added: "admin_added",
         insufficient_instant_places: "insufficient_instant_places",
       },
       prefix: true

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
