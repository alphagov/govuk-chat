class NotifySlackWaitingListFullJob < ApplicationJob
  queue_as :default

  def perform
    SlackPoster.waiting_list_full
  end
end
