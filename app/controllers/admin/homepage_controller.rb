class Admin::HomepageController < Admin::BaseController
  def index
    @questions_total = Question.count
    @early_access_users_total = EarlyAccessUser.count
    @waiting_list_users_total = WaitingListUser.count
  end
end
