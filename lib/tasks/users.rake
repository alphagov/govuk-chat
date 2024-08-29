namespace :users do
  desc "Promote batch of WaitingListUsers to be EarlyAccessUsers"
  task promote_waiting_list: :environment do
    ActiveRecord::Base.transaction do
      WaitingListUser.limit(50).all.each do |waiting_list_user|
        EarlyAccessUser.promote_waiting_list_user(waiting_list_user)
      end
    end
  end
end
