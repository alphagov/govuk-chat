class DeletedWaitingListUser < ApplicationRecord
  enum :deletion_type,
       { unsubscribe: "unsubscribe", admin: "admin", promotion: "promotion" },
       prefix: true
  enum :user_source, WaitingListUser::SOURCE_ENUM, prefix: true
end
