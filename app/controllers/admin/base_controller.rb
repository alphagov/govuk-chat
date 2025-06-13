class Admin::BaseController < ApplicationController
  layout "admin"
  before_action { authorise_user!(SignonUser::Permissions::ADMIN_AREA) }
  before_action { Current.signon_user = current_user }

  def authorise_admin_settings
    authorise_user!(SignonUser::Permissions::ADMIN_AREA_SETTINGS)
  end
end
