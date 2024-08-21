class WaitingListUser < ApplicationRecord
  include PilotUser

  enum :source,
       {
         admin_added: "admin_added",
         insufficient_instant_places: "insufficient_instant_places",
       },
       prefix: true
end
