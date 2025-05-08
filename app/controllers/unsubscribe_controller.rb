class UnsubscribeController < ApplicationController
  # Minimal implementation kept temporarily so that unsubscribe URLs used in
  # mailers can be generated. TODO: Remove this once the mailers are updated.

  def early_access_user
    head :gone
  end

  def waiting_list_user
    head :gone
  end
end
