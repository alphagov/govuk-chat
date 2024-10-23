class Admin::HomepageController < Admin::BaseController
  def index
    @questions_total = Question.count
    early_access_users_current = EarlyAccessUser.count
    waiting_list_users_current = WaitingListUser.count

    unsubscribed_early_access_users = DeletedEarlyAccessUser.deletion_type_unsubscribe.count
    admin_deleted_early_access_users = DeletedEarlyAccessUser.deletion_type_admin.count

    @early_access_user_stats = {
      current: early_access_users_current,
      unsubscribed: unsubscribed_early_access_users,
      admin_deleted: admin_deleted_early_access_users,
      total: [early_access_users_current,
              unsubscribed_early_access_users,
              admin_deleted_early_access_users].sum,
    }

    promoted_waiting_list_users = DeletedWaitingListUser.deletion_type_promotion.count
    unsubscribed_waiting_list_users = DeletedWaitingListUser.deletion_type_unsubscribe.count
    admin_deleted_waiting_list_users = DeletedWaitingListUser.deletion_type_admin.count
    percentage_of_waiting_list_used = (waiting_list_users_current.to_f / Settings.instance.max_waiting_list_places) * 100

    @waiting_list_user_stats = {
      current: waiting_list_users_current,
      promoted: promoted_waiting_list_users,
      unsubscribed: unsubscribed_waiting_list_users,
      admin_deleted: admin_deleted_waiting_list_users,
      total: [waiting_list_users_current,
              promoted_waiting_list_users,
              unsubscribed_waiting_list_users,
              admin_deleted_waiting_list_users].sum,
      percentage_of_waiting_list_used:,
    }
  end
end
