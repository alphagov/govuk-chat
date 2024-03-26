class ChatController < ApplicationController
  def index
    expires_in(5.minutes, public: true) unless Rails.env.development?
  end
end
